#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <linux/uinput.h>

struct named_key { const char *name; int code; };
static const struct named_key keys[] = {
    {"ctrl", KEY_LEFTCTRL}, {"shift", KEY_LEFTSHIFT}, {"alt", KEY_LEFTALT}, {"super", KEY_LEFTMETA},
    {"tab", KEY_TAB}, {"enter", KEY_ENTER}, {"esc", KEY_ESC}, {"space", KEY_SPACE}, {"backspace", KEY_BACKSPACE},
    {"a", KEY_A}, {"b", KEY_B}, {"c", KEY_C}, {"d", KEY_D}, {"e", KEY_E}, {"f", KEY_F}, {"g", KEY_G},
    {"h", KEY_H}, {"i", KEY_I}, {"j", KEY_J}, {"k", KEY_K}, {"l", KEY_L}, {"m", KEY_M}, {"n", KEY_N},
    {"o", KEY_O}, {"p", KEY_P}, {"q", KEY_Q}, {"r", KEY_R}, {"s", KEY_S}, {"t", KEY_T}, {"u", KEY_U},
    {"v", KEY_V}, {"w", KEY_W}, {"x", KEY_X}, {"y", KEY_Y}, {"z", KEY_Z},
};

static int lookup(const char *name) {
    for (size_t i = 0; i < sizeof keys / sizeof keys[0]; i++)
        if (!strcmp(keys[i].name, name)) return keys[i].code;
    return -1;
}

static void emit(int fd, int type, int code, int value) {
    struct input_event ev = {0};
    ev.type = type; ev.code = code; ev.value = value;
    if (write(fd, &ev, sizeof ev) < 0) perror("write");
}

static void press_combo(int fd, char *combo) {
    int codes[8]; int n = 0;
    for (char *tok = strtok(combo, "+"); tok && n < 8; tok = strtok(NULL, "+")) {
        int c = lookup(tok);
        if (c < 0) { fprintf(stderr, "keytap: unknown key '%s'\n", tok); exit(2); }
        codes[n++] = c;
    }
    for (int i = 0; i < n; i++) { emit(fd, EV_KEY, codes[i], 1); emit(fd, EV_SYN, SYN_REPORT, 0); usleep(15000); }
    for (int i = n - 1; i >= 0; i--) { emit(fd, EV_KEY, codes[i], 0); emit(fd, EV_SYN, SYN_REPORT, 0); usleep(15000); }
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: keytap COMBO [COMBO...]   e.g. keytap ctrl+v tab\n"); return 1; }
    int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (fd < 0) { perror("/dev/uinput"); return 1; }
    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    for (size_t i = 0; i < sizeof keys / sizeof keys[0]; i++) ioctl(fd, UI_SET_KEYBIT, keys[i].code);
    struct uinput_setup us = {0};
    us.id.bustype = BUS_VIRTUAL; us.id.vendor = 0x1; us.id.product = 0x1;
    strcpy(us.name, "keytap virtual keyboard");
    ioctl(fd, UI_DEV_SETUP, &us);
    ioctl(fd, UI_DEV_CREATE);
    usleep(300000);
    for (int i = 1; i < argc; i++) { press_combo(fd, argv[i]); usleep(60000); }
    usleep(100000);
    ioctl(fd, UI_DEV_DESTROY);
    close(fd);
    return 0;
}
