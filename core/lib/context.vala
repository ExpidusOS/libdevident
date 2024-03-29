namespace Devident {
  internal static Context ?global_context;

  public class Context : GLib.Object, GLib.Initable {
    private GLib.HashTable <string, Provider> _providers;
    private GLib.List <Device> _devices;
    private string ?_device_id;

    public string device_id {
      get {
        try {
          if (this._device_id == null) {
            this._device_id = Device.get_host_id();
          }
        } catch (GLib.Error e) {
          GLib.critical(N_("Failed to get the host device ID: %s:%d: %s"), e.domain.to_string(), e.code, e.message);
        }
        return this._device_id;
      }
    }

    public static unowned Context ? get_global() {
      if (global_context == null) {
#if HAS_LIBPEAS
        try {
          global_context = new PeasContext();
            GLib.debug(N_("Global context uses libpeas"));
          return global_context;
        } catch (GLib.Error e) {
          GLib.critical(N_("Failed to create a new context: %s:%d: %s"), e.domain.to_string(), e.code, e.message);
          global_context = null;
        }
#endif
#if HAS_GMODULE
        if (GLib.Module.supported()) {
          try {
            global_context = new GModuleContext();
            GLib.debug(N_("Global context uses GModule"));
            return global_context;
          } catch (GLib.Error e) {
            GLib.critical(N_("Failed to create a new context: %s:%d: %s"), e.domain.to_string(), e.code, e.message);
            global_context = null;
          }
        }
#endif

        try {
          global_context = new Context();
          GLib.debug(N_("Using base context as the global context"));
          return global_context;
        } catch (GLib.Error e) {
          GLib.critical(N_("Failed to create a new context: %s:%d: %s"), e.domain.to_string(), e.code, e.message);
          global_context = null;
        }
      }
      return global_context;
    }

    public Context() throws GLib.Error {
      Object();
      this.init(null);
    }

    construct {
      GLib.Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
      GLib.Intl.bindtextdomain(GETTEXT_PACKAGE, LOCALDIR);
      this._providers = new GLib.HashTable <string, Provider>(GLib.str_hash, GLib.str_equal);
    }

    public bool init(GLib.Cancellable ?cancellable = null) throws GLib.Error {
      if (this._device_id == null) {
        this._device_id = Device.get_host_id();
      }
      return true;
    }

    public void add_provider(Provider provider) {
      var name = provider.name;
      if (!this._providers.contains(name)) {
        GLib.debug(N_("Adding provider \"%s\" %p"), name, provider);
        this._providers.set(name, provider);
      }
    }

    public void remove_provider(Provider provider) {
      var name = provider.name;
      if (this._providers.contains(name)) {
        GLib.debug(N_("Removing provider \"%s\" %p"), name, provider);
        this._providers.remove(name);
      }
    }

    internal GLib.List <string> get_cached_device_ids() {
      var list = new GLib.List <string>();
      foreach (var dev in this._devices) {
        list.append(dev.id);
      }
      return list;
    }

    internal GLib.List <string> get_uncached_device_ids() {
      var list = new GLib.List <string>();
      foreach (var provider in this._providers.get_values()) {
        var device_provider = provider.get_device_provider();
        if (device_provider == null) {
          continue;
        }

        var devlist = device_provider.get_device_ids();
        foreach (var dev in devlist) {
          if (list.find(dev) != null) {
            continue;
          }
          list.append(dev);
        }
      }
      return list;
    }

    public GLib.List <string> get_device_ids() {
      var list     = this.get_cached_device_ids();
      var uncached = this.get_uncached_device_ids();

      foreach (var item in uncached) {
        if (list.find(item) != null) {
          continue;
        }
        list.append(item);
      }
      return list;
    }

    internal unowned Device ? find_cached_device(string id) {
      foreach (unowned var device in this._devices) {
        if (device.id == id) {
          return device;
        }
      }
      return null;
    }

    internal Device ? find_uncached_device(string id) {
      foreach (var provider in this._providers.get_values()) {
        var device_provider = provider.get_device_provider();
        if (device_provider == null) {
          continue;
        }

        var device = device_provider.get_device(id);
        if (device == null) {
          continue;
        }
        return device;
      }
      return null;
    }

    public unowned Device ? find_device(string id) {
      unowned var cached = this.find_cached_device(id);
      if (cached == null) {
        var uncached = this.find_uncached_device(id);
        if (uncached == null) {
          return null;
        }
        this._devices.append(uncached);
        return this._devices.find_custom(uncached, (a, b) => GLib.strcmp(a.id, b.id)).data;
      }
      return cached;
    }

    public unowned Device ? get_default() {
      return this.find_device(this.device_id);
    }
  }
}
