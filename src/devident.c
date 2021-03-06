#include <devident.h>
#include <glib.h>

devident_t* devident_new(GError** error) {
	gchar* model = NULL;
	if (!g_file_test("/sys/firmware/devicetree/base/model", G_FILE_TEST_IS_REGULAR)) {
		if (!g_file_test("/sys/devices/virtual/dmi/id/product_name", G_FILE_TEST_IS_REGULAR)) {
			g_set_error(error, 0, 0, "Failed to find a sysfs file to identify the device.");
			return NULL;
		}

		if (!g_file_get_contents("/sys/devices/virtual/dmi/id/product_name", &model, NULL, error)) return NULL;
	} else {
		if (!g_file_get_contents("/sys/firmware/devicetree/base/model", &model, NULL, error)) return NULL;
	}

	devident_t* self = g_new0(devident_t, 1);
	if (self == NULL) {
		g_set_error(error, 0, 0, "Failed to allocate");
		return NULL;
	}

	if (g_str_has_prefix(model, "Pine64 PinePhone")) {
		self->type = DEVIDENT_TYPE_PHONE;
		self->model = g_strdup("PinePhone");
		gchar** v = g_strsplit(model, " ", 0);
		if (v == NULL) {
			g_set_error(error, 0, 0, "Failed to split string");
                	g_clear_pointer(&model, g_free);
        		g_free(self);
			return NULL;
		}
		v[2][strlen(v[2] - 1)] = 0;
		self->rev = (gchar*)(v[2] + 1);
		g_strfreev(v);
		self->maker = g_strdup("PINE64");
		self->touchinput_path = "/dev/input/event1";
		self->screen_name = "DSI-1";
		self->screen_scale[0] = 0.8;
		self->screen_scale[1] = 0.8;
	} else g_clear_pointer(&model, g_free);

	if (model == NULL) {
		// TODO: maybe default to using the sysfs when the "database" has no entry
		self->type = DEVIDENT_TYPE_UNKNOWN;
		self->model = g_strdup("Unknown");
		self->rev = g_strdup("Unknown");
		self->maker = g_strdup("Unknown");
		self->screen_scale[0] = 1.0;
		self->screen_scale[1] = 1.0;
	} else g_clear_pointer(&model, g_free);
	return self;
}

void devident_destroy(devident_t* self) {
	g_clear_pointer(&self->model, g_free);
	g_clear_pointer(&self->rev, g_free);
	g_clear_pointer(&self->maker, g_free);
	g_free(self);
}
