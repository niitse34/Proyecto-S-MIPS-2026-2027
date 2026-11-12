import com.cburch.logisim.comp.ComponentFactory;
import com.cburch.logisim.data.Attribute;
import com.cburch.logisim.data.AttributeSet;
import com.cburch.logisim.std.Builtin;
import com.cburch.logisim.tools.AddTool;
import com.cburch.logisim.tools.Library;
import com.cburch.logisim.tools.Tool;
import java.util.ArrayList;
import java.util.List;

/**
 * Vuelca los atributos de los componentes de Logisim tal como se escriben en el
 * archivo .circ: nombre del atributo, valor por defecto (toStandardString) y las
 * cadenas que acepta parse(). Es la referencia para generar circuitos por script.
 *
 * Uso: java -Djava.util.prefs.PreferencesFactory=MemPrefsFactory \
 *           -cp "<jar>;<clases>" ListAttrs.java [filtro-del-nombre]
 *
 * Un atributo con nombre o valor no aceptado hace que Logisim rechace el archivo
 * completo, asi que conviene comprobar aqui antes de escribir el .circ.
 */
class ListAttrs {
  static final String[] CANDIDATOS = {
      "0", "1", "2", "3", "4", "5", "6", "7", "8", "16", "31", "32", "64",
      "true", "false", "yes", "no", "signed", "unsigned", "twosComplement",
      "logicalLeft", "logicalRight", "arithmeticRight", "rotateLeft", "rotateRight",
      "ll", "lr", "ar", "rl", "rr", "zero", "sign", "input", "output",
      "east", "west", "north", "south", "none", "bibus", "separate",
      "byteEnables", "oneEnable", "rising", "falling", "high", "low",
      "classic", "evolution", "center", "left", "right",
  };

  @SuppressWarnings({"unchecked", "rawtypes"})
  static void volcar(Attribute atributo, AttributeSet conjunto) {
    Object defecto = conjunto.getValue(atributo);
    String textoDefecto;
    try {
      textoDefecto = atributo.toStandardString(defecto);
    } catch (Throwable e) {
      textoDefecto = String.valueOf(defecto);
    }
    String muestra = "";
    try { muestra = atributo.toDisplayString(defecto); } catch (Throwable ignored) { }
    System.out.printf("   %-14s = %-16s (%s)%n", atributo.getName(), "\"" + textoDefecto + "\"", muestra);
    List<String> validos = new ArrayList<>();
    for (String candidato : CANDIDATOS) {
      try {
        Object valor = atributo.parse(candidato);
        String texto = atributo.toStandardString(valor);
        String par = candidato + " -> " + texto;
        if (!texto.equals(textoDefecto) && !validos.contains(par)) validos.add(par);
      } catch (Throwable ignored) { }
    }
    if (!validos.isEmpty()) System.out.println("        acepta: " + String.join(" | ", validos));
  }

  public static void main(String[] args) {
    String filtro = args.length > 0 ? args[0].toLowerCase() : "";
    for (Library libreria : new Builtin().getLibraries()) {
      for (Tool herramienta : libreria.getTools()) {
        if (!(herramienta instanceof AddTool)) continue;
        ComponentFactory fabrica = ((AddTool) herramienta).getFactory();
        if (!fabrica.getName().toLowerCase().contains(filtro)) continue;
        System.out.println("== " + fabrica.getName() + "  (libreria: " + libreria.getName() + ")");
        AttributeSet conjunto;
        try {
          conjunto = fabrica.createAttributeSet();
        } catch (Throwable e) {
          System.out.println("   no se pudo crear el conjunto de atributos: " + e);
          continue;
        }
        for (Attribute<?> atributo : conjunto.getAttributes()) volcar(atributo, conjunto);
      }
    }
  }
}
