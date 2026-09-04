#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <wayland-client.h>
#include "cosmic-toplevel-info-unstable-v1-client-protocol.h"
#include "cosmic-toplevel-management-unstable-v1-client-protocol.h"

struct toplevel {
    struct zcosmic_toplevel_handle_v1 *handle;
    char *title;
    char *app_id;
    int minimized;
    int done;
    struct toplevel *next;
};

static struct zcosmic_toplevel_info_v1 *info;
static struct zcosmic_toplevel_manager_v1 *manager;
static struct toplevel *toplevels;

static void handle_title(void *data, struct zcosmic_toplevel_handle_v1 *h, const char *title) {
    struct toplevel *t = data;
    free(t->title);
    t->title = strdup(title);
}

static void handle_app_id(void *data, struct zcosmic_toplevel_handle_v1 *h, const char *app_id) {
    struct toplevel *t = data;
    free(t->app_id);
    t->app_id = strdup(app_id);
}

static void handle_state(void *data, struct zcosmic_toplevel_handle_v1 *h, struct wl_array *state) {
    struct toplevel *t = data;
    t->minimized = 0;
    uint32_t *entry;
    wl_array_for_each(entry, state) {
        if (*entry == ZCOSMIC_TOPLEVEL_HANDLE_V1_STATE_MINIMIZED) t->minimized = 1;
    }
}

static void handle_done(void *data, struct zcosmic_toplevel_handle_v1 *h) {
    struct toplevel *t = data;
    t->done = 1;
}

static void handle_closed(void *data, struct zcosmic_toplevel_handle_v1 *h) {}
static void handle_output(void *data, struct zcosmic_toplevel_handle_v1 *h, struct wl_output *o) {}
static void handle_workspace(void *data, struct zcosmic_toplevel_handle_v1 *h, struct zcosmic_workspace_handle_v1 *w) {}
static void handle_geometry(void *data, struct zcosmic_toplevel_handle_v1 *h, struct wl_output *o, int32_t x, int32_t y, int32_t w, int32_t hh) {}
static void handle_ext_workspace(void *data, struct zcosmic_toplevel_handle_v1 *h, struct ext_workspace_handle_v1 *w) {}

static const struct zcosmic_toplevel_handle_v1_listener handle_listener = {
    .closed = handle_closed,
    .done = handle_done,
    .title = handle_title,
    .app_id = handle_app_id,
    .output_enter = handle_output,
    .output_leave = handle_output,
    .workspace_enter = handle_workspace,
    .workspace_leave = handle_workspace,
    .state = handle_state,
    .geometry = handle_geometry,
    .ext_workspace_enter = handle_ext_workspace,
    .ext_workspace_leave = handle_ext_workspace,
};

static void info_toplevel(void *data, struct zcosmic_toplevel_info_v1 *i, struct zcosmic_toplevel_handle_v1 *handle) {
    struct toplevel *t = calloc(1, sizeof *t);
    t->handle = handle;
    t->title = strdup("");
    t->app_id = strdup("");
    t->next = toplevels;
    toplevels = t;
    zcosmic_toplevel_handle_v1_add_listener(handle, &handle_listener, t);
}

static void info_finished(void *data, struct zcosmic_toplevel_info_v1 *i) {}
static void info_done(void *data, struct zcosmic_toplevel_info_v1 *i) {}

static const struct zcosmic_toplevel_info_v1_listener info_listener = {
    .toplevel = info_toplevel,
    .finished = info_finished,
    .done = info_done,
};

static void manager_capabilities(void *data, struct zcosmic_toplevel_manager_v1 *m, struct wl_array *caps) {}

static const struct zcosmic_toplevel_manager_v1_listener manager_listener = {
    .capabilities = manager_capabilities,
};

static void registry_global(void *data, struct wl_registry *registry, uint32_t name, const char *interface, uint32_t version) {
    if (strcmp(interface, zcosmic_toplevel_info_v1_interface.name) == 0) {
        info = wl_registry_bind(registry, name, &zcosmic_toplevel_info_v1_interface, 1);
        zcosmic_toplevel_info_v1_add_listener(info, &info_listener, NULL);
    } else if (strcmp(interface, zcosmic_toplevel_manager_v1_interface.name) == 0) {
        manager = wl_registry_bind(registry, name, &zcosmic_toplevel_manager_v1_interface, 1);
        zcosmic_toplevel_manager_v1_add_listener(manager, &manager_listener, NULL);
    }
}

static void registry_global_remove(void *data, struct wl_registry *registry, uint32_t name) {}

static const struct wl_registry_listener registry_listener = {
    .global = registry_global,
    .global_remove = registry_global_remove,
};

static char *state_path(void) {
    static char path[4096];
    const char *home = getenv("HOME");
    snprintf(path, sizeof path, "%s/.cache/show-desktop", home ? home : "/tmp");
    mkdir(path, 0700);
    strncat(path, "/minimized", sizeof path - strlen(path) - 1);
    return path;
}

static void remember_minimized(void) {
    FILE *f = fopen(state_path(), "w");
    if (!f) return;
    for (struct toplevel *t = toplevels; t; t = t->next) {
        if (!t->minimized) fprintf(f, "%s\t%s\n", t->app_id, t->title);
    }
    fclose(f);
}

static int was_minimized_by_us(struct toplevel *t) {
    FILE *f = fopen(state_path(), "r");
    if (!f) return 1;
    char line[8192];
    int found = 0;
    while (fgets(line, sizeof line, f)) {
        line[strcspn(line, "\n")] = 0;
        char *tab = strchr(line, '\t');
        if (!tab) continue;
        *tab = 0;
        if (strcmp(line, t->app_id) == 0 && strcmp(tab + 1, t->title) == 0) {
            found = 1;
            break;
        }
    }
    fclose(f);
    return found;
}

static void minimize_all(void) {
    remember_minimized();
    for (struct toplevel *t = toplevels; t; t = t->next) {
        if (!t->minimized) zcosmic_toplevel_manager_v1_set_minimized(manager, t->handle);
    }
}

static void restore(int only_ours) {
    for (struct toplevel *t = toplevels; t; t = t->next) {
        if (t->minimized && (!only_ours || was_minimized_by_us(t)))
            zcosmic_toplevel_manager_v1_unset_minimized(manager, t->handle);
    }
    remove(state_path());
}

static int any_visible(void) {
    for (struct toplevel *t = toplevels; t; t = t->next) {
        if (!t->minimized) return 1;
    }
    return 0;
}

static void list(void) {
    for (struct toplevel *t = toplevels; t; t = t->next) {
        printf("%s\t%s\t%s\n", t->minimized ? "min" : "vis", t->app_id, t->title);
    }
}

int main(int argc, char **argv) {
    const char *mode = argc > 1 ? argv[1] : "toggle";
    struct wl_display *display = wl_display_connect(NULL);
    if (!display) {
        fprintf(stderr, "kein Wayland-Display\n");
        return 1;
    }
    struct wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, NULL);
    wl_display_roundtrip(display);
    if (!info || !manager) {
        fprintf(stderr, "Compositor bietet zcosmic_toplevel_info/manager nicht an\n");
        return 1;
    }
    wl_display_roundtrip(display);
    wl_display_roundtrip(display);

    if (strcmp(mode, "list") == 0) list();
    else if (strcmp(mode, "minimize") == 0) minimize_all();
    else if (strcmp(mode, "restore") == 0) restore(0);
    else if (any_visible()) minimize_all();
    else restore(1);

    wl_display_roundtrip(display);
    wl_display_disconnect(display);
    return 0;
}
