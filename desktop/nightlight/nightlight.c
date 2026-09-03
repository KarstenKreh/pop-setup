#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include <time.h>
#include <unistd.h>
#include <poll.h>
#include <signal.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <wayland-client.h>
#include "wlr-layer-shell-client-protocol.h"

/* ---------- Konfiguration ---------- */
static char cfg_path[512];
static struct { char mode[16]; int temp, day_temp, night_temp;
                int sunset_m, sunrise_m, fade_m, strength; double max_alpha; } C = {
    "auto", 3400, 6500, 3400, 20*60+30, 7*60, 45, 60, 0.60 };
static time_t cfg_mtime = 0;

static int parse_hhmm(const char *s){ int h=0,m=0; if(sscanf(s,"%d:%d",&h,&m)!=2) return -1; return h*60+m; }

static void load_cfg(void){
    struct stat st;
    if (stat(cfg_path,&st)!=0) return;
    if (st.st_mtime==cfg_mtime) return;
    cfg_mtime = st.st_mtime;
    FILE *f=fopen(cfg_path,"r"); if(!f) return;
    char line[256];
    while(fgets(line,sizeof line,f)){
        char k[64],v[128];
        if(sscanf(line," %63[^= \t] = %127[^\n\r ]",k,v)!=2) continue;
        if(!strcmp(k,"mode")) snprintf(C.mode,sizeof C.mode,"%s",v);
        else if(!strcmp(k,"temp")) C.temp=atoi(v);
        else if(!strcmp(k,"day_temp")) C.day_temp=atoi(v);
        else if(!strcmp(k,"night_temp")) C.night_temp=atoi(v);
        else if(!strcmp(k,"sunset")) { int t=parse_hhmm(v); if(t>=0) C.sunset_m=t; }
        else if(!strcmp(k,"sunrise")){ int t=parse_hhmm(v); if(t>=0) C.sunrise_m=t; }
        else if(!strcmp(k,"fade")) C.fade_m=atoi(v);
        else if(!strcmp(k,"strength")) C.strength=atoi(v);
        else if(!strcmp(k,"max_alpha")) C.max_alpha=atof(v);
    }
    fclose(f);
}

/* ---------- Farbtemperatur -> Overlay-Farbe ---------- */
/* Schwarzkoerper-Naeherung (Tanner Helland), normiert auf 6500K = neutral. */
static void bb_rgb(double K, double *r, double *g, double *b){
    double t = K/100.0, R,G,B;
    if (t<=66) R=255; else { R=329.698727446*pow(t-60,-0.1332047592); }
    if (t<=66) G=99.4708025861*log(t)-161.1195681661;
    else       G=288.1221695283*pow(t-60,-0.0755148492);
    if (t>=66) B=255; else if (t<=19) B=0;
    else       B=138.5177312231*log(t-10)-305.0447927307;
    if(R<0)R=0; if(R>255)R=255; if(G<0)G=0; if(G>255)G=255; if(B<0)B=0; if(B>255)B=255;
    /* Normierung auf den 6500K-Weisspunkt dieser Formel */
    *r=R/255.0; *g=G/254.1198; *b=B/250.0872;
    if(*r>1)*r=1; if(*g>1)*g=1; if(*b>1)*b=1;
}

/* Wir koennen nur alpha-blenden: out = OV*a + under*(1-a).
   Fuer weisses "under" soll out == (rM,gM,bM) gelten.
   Blau: OV_b=0  ->  a = 1-bM
   Rot:  OV_r=1  (rM ist bei warmen Temperaturen 1)
   Gruen: OV_g = (gM-bM)/(1-bM)                                        */
static uint32_t argb_for_temp(double K, double max_alpha, int strength){
    double rM,gM,bM; bb_rgb(K,&rM,&gM,&bM);
    double a = (1.0-bM) * (strength<0?0:(strength>100?100:strength))/100.0;
    if (a < 0.002) return 0;                 /* kein Filter noetig */
    if (a > max_alpha) a = max_alpha;
    double ovg = (gM-bM)/(1.0-bM); if(ovg<0)ovg=0; if(ovg>1)ovg=1;
    /* ovg bleibt die Farbtoncharakteristik; a steuert die Staerke */
    double ovr = rM;               if(ovr<0)ovr=0; if(ovr>1)ovr=1;
    /* ARGB8888 mit vormultipliziertem Alpha */
    uint32_t A=(uint32_t)lround(a*255.0);
    uint32_t R=(uint32_t)lround(ovr*a*255.0);
    uint32_t G=(uint32_t)lround(ovg*a*255.0);
    return (A<<24)|(R<<16)|(G<<8)|0;
}

static double current_temp(void){
    if(!strcmp(C.mode,"off")) return 6500.0;
    if(!strcmp(C.mode,"on"))  return (double)C.temp;
    /* auto: weiche Ueberblendung um Sonnenunter-/aufgang */
    time_t now=time(NULL); struct tm tm; localtime_r(&now,&tm);
    double m = tm.tm_hour*60 + tm.tm_min + tm.tm_sec/60.0;
    double f = C.fade_m>0 ? C.fade_m : 1;
    double ss=C.sunset_m, sr=C.sunrise_m;
    double d=C.day_temp, n=C.night_temp;
    /* Abstand in Minuten, zyklisch ueber 24h */
    double dss = fmod(m-ss+1440.0,1440.0);   /* Zeit seit Sonnenuntergang */
    double dsr = fmod(m-sr+1440.0,1440.0);   /* Zeit seit Sonnenaufgang  */
    if (dss < f)   return d + (n-d)*(dss/f);          /* Abenddaemmerung */
    if (dsr < f)   return n + (d-n)*(dsr/f);          /* Morgendaemmerung */
    return (dss < dsr) ? n : d;                       /* Nacht bzw. Tag  */
}

/* ---------- Wayland ---------- */
static struct wl_compositor *comp; static struct wl_shm *shm;
static struct zwlr_layer_shell_v1 *shell; static struct wl_display *dpy;
static uint32_t cur_argb = 0xffffffff; static volatile sig_atomic_t running=1;

struct out { struct wl_output *wl; uint32_t name; struct wl_surface *surf;
             struct zwlr_layer_surface_v1 *ls; int w,h,ready;
             struct wl_buffer *buf; void *map; size_t maplen; struct out *next; };
static struct out *outs;

static struct wl_buffer *make_buffer(struct out *o, uint32_t argb){
    if(o->w<=0||o->h<=0) return NULL;
    size_t stride=(size_t)o->w*4, size=stride*o->h;
    int fd=memfd_create("nl",MFD_CLOEXEC); if(fd<0) return NULL;
    if(ftruncate(fd,size)<0){ close(fd); return NULL; }
    uint32_t *px=mmap(NULL,size,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
    if(px==MAP_FAILED){ close(fd); return NULL; }
    size_t n=size/4; for(size_t i=0;i<n;i++) px[i]=argb;
    struct wl_shm_pool *pool=wl_shm_create_pool(shm,fd,size);
    struct wl_buffer *b=wl_shm_pool_create_buffer(pool,0,o->w,o->h,stride,WL_SHM_FORMAT_ARGB8888);
    wl_shm_pool_destroy(pool); close(fd);
    if(o->map){ munmap(o->map,o->maplen); }
    o->map=px; o->maplen=size;
    return b;
}

static void redraw(struct out *o){
    if(!o->ready) return;
    /* Filter aus = vollstaendig transparenter Buffer. Kein Unmap, damit das
       Wiedereinblenden ohne neues configure funktioniert. */
    struct wl_buffer *b=make_buffer(o,cur_argb);
    if(!b) return;
    if(o->buf) wl_buffer_destroy(o->buf);
    o->buf=b;
    struct wl_region *empty=wl_compositor_create_region(comp);   /* klickdurchlaessig */
    wl_surface_set_input_region(o->surf,empty);
    wl_region_destroy(empty);
    wl_surface_attach(o->surf,b,0,0);
    wl_surface_damage_buffer(o->surf,0,0,o->w,o->h);
    wl_surface_commit(o->surf);
}

static void ls_configure(void *d,struct zwlr_layer_surface_v1 *ls,uint32_t serial,uint32_t w,uint32_t h){
    struct out *o=d;
    zwlr_layer_surface_v1_ack_configure(ls,serial);
    o->w=(int)w; o->h=(int)h; o->ready=1;
    redraw(o);
}
static void ls_closed(void *d,struct zwlr_layer_surface_v1 *ls){ (void)d;(void)ls; }
static const struct zwlr_layer_surface_v1_listener ls_lst={ls_configure,ls_closed};

static void add_layer(struct out *o){
    o->surf=wl_compositor_create_surface(comp);
    o->ls=zwlr_layer_shell_v1_get_layer_surface(shell,o->surf,o->wl,
            ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY,"nightlight");
    zwlr_layer_surface_v1_add_listener(o->ls,&ls_lst,o);
    zwlr_layer_surface_v1_set_anchor(o->ls,
        ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP|ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM|
        ZWLR_LAYER_SURFACE_V1_ANCHOR_LEFT|ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT);
    zwlr_layer_surface_v1_set_exclusive_zone(o->ls,-1);
    zwlr_layer_surface_v1_set_keyboard_interactivity(o->ls,
        ZWLR_LAYER_SURFACE_V1_KEYBOARD_INTERACTIVITY_NONE);
    struct wl_region *empty=wl_compositor_create_region(comp);
    wl_surface_set_input_region(o->surf,empty);
    wl_region_destroy(empty);
    wl_surface_commit(o->surf);
}

static void reg_global(void *d,struct wl_registry *r,uint32_t name,const char *iface,uint32_t ver){
    (void)d;
    if(!strcmp(iface,wl_compositor_interface.name))
        comp=wl_registry_bind(r,name,&wl_compositor_interface,ver<4?ver:4);
    else if(!strcmp(iface,wl_shm_interface.name))
        shm=wl_registry_bind(r,name,&wl_shm_interface,1);
    else if(!strcmp(iface,zwlr_layer_shell_v1_interface.name))
        shell=wl_registry_bind(r,name,&zwlr_layer_shell_v1_interface,ver<4?ver:4);
    else if(!strcmp(iface,wl_output_interface.name)){
        struct out *o=calloc(1,sizeof *o);
        o->wl=wl_registry_bind(r,name,&wl_output_interface,ver<4?ver:4);
        o->name=name; o->next=outs; outs=o;
        if(comp&&shell) add_layer(o);
    }
}
static void reg_remove(void *d,struct wl_registry *r,uint32_t name){
    (void)d;(void)r;
    struct out **p=&outs;
    while(*p){ if((*p)->name==name){ struct out *o=*p; *p=o->next;
            if(o->ls) zwlr_layer_surface_v1_destroy(o->ls);
            if(o->surf) wl_surface_destroy(o->surf);
            if(o->buf) wl_buffer_destroy(o->buf);
            if(o->map) munmap(o->map,o->maplen);
            wl_output_destroy(o->wl); free(o); return; } p=&(*p)->next; }
}
static const struct wl_registry_listener reg_lst={reg_global,reg_remove};

static void on_sig(int s){ (void)s; running=0; }

int main(int argc,char **argv){
    const char *home=getenv("HOME");
    snprintf(cfg_path,sizeof cfg_path,"%s/.config/cosmic-nightlight/config",home?home:".");
    if(argc>1) snprintf(cfg_path,sizeof cfg_path,"%s",argv[1]);
    load_cfg();

    dpy=wl_display_connect(NULL);
    if(!dpy){ fprintf(stderr,"Keine Wayland-Verbindung\n"); return 1; }
    struct wl_registry *reg=wl_display_get_registry(dpy);
    wl_registry_add_listener(reg,&reg_lst,NULL);
    wl_display_roundtrip(dpy); wl_display_roundtrip(dpy);
    if(!comp||!shm||!shell){ fprintf(stderr,"Fehlende Protokolle (compositor/shm/layer-shell)\n"); return 1; }
    for(struct out *o=outs;o;o=o->next) if(!o->ls) add_layer(o);
    wl_display_roundtrip(dpy);

    signal(SIGINT,on_sig); signal(SIGTERM,on_sig);

    while(running){
        load_cfg();
        uint32_t want=argb_for_temp(current_temp(),C.max_alpha,C.strength);
        if(want!=cur_argb){ cur_argb=want; for(struct out *o=outs;o;o=o->next) redraw(o); }
        wl_display_flush(dpy);
        struct pollfd pfd={wl_display_get_fd(dpy),POLLIN,0};
        int n=poll(&pfd,1,2000);
        if(n>0 && (pfd.revents&POLLIN)){ if(wl_display_dispatch(dpy)<0) break; }
        else wl_display_dispatch_pending(dpy);
    }
    for(struct out *o=outs;o;o=o->next){
        if(o->ls) zwlr_layer_surface_v1_destroy(o->ls);
        if(o->surf) wl_surface_destroy(o->surf);
    }
    wl_display_flush(dpy); wl_display_disconnect(dpy);
    return 0;
}
