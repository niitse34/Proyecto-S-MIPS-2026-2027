import java.util.HashMap;
import java.util.Map;
import java.util.prefs.AbstractPreferences;
import java.util.prefs.Preferences;
import java.util.prefs.PreferencesFactory;

/**
 * Preferencias en memoria para poder cargar Logisim sin el registro de Windows.
 *
 * Logisim escribe sus opciones en java.util.prefs; en equipos donde el registro
 * no esta disponible (o el sandbox lo deniega) la clase AppPreferences falla en
 * su inicializacion estatica. Compilando esta clase y pasando
 *   -Djava.util.prefs.PreferencesFactory=MemPrefsFactory
 * con su directorio en el classpath, Logisim arranca igual.
 */
public class MemPrefsFactory implements PreferencesFactory {

  static final MemPrefs RAIZ = new MemPrefs(null, "");

  static class MemPrefs extends AbstractPreferences {
    final Map<String, String> valores = new HashMap<>();
    final Map<String, MemPrefs> hijos = new HashMap<>();

    MemPrefs(AbstractPreferences padre, String nombre) {
      super(padre, nombre);
    }

    @Override protected void putSpi(String clave, String valor) { valores.put(clave, valor); }
    @Override protected String getSpi(String clave) { return valores.get(clave); }
    @Override protected void removeSpi(String clave) { valores.remove(clave); }
    @Override protected void removeNodeSpi() { }
    @Override protected String[] keysSpi() { return valores.keySet().toArray(new String[0]); }
    @Override protected String[] childrenNamesSpi() { return hijos.keySet().toArray(new String[0]); }
    @Override protected AbstractPreferences childSpi(String nombre) {
      return hijos.computeIfAbsent(nombre, n -> new MemPrefs(this, n));
    }
    @Override protected void flushSpi() { }
    @Override protected void syncSpi() { }
  }

  public Preferences userRoot() { return RAIZ; }
  public Preferences systemRoot() { return RAIZ; }
}
