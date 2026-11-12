# Plan de implementación de la CPU S-MIPS: multiciclo y modular

Propuesta de trabajo para `Proyecto-S-MIPS-2026-2027` · 2026-11-11
Especificación de referencia: [`docs/guide.pdf`](guide.pdf) (fuente [`docs/guide.tex`](guide.tex)).
Este documento planifica; no modifica la placa ni el circuito entregado.

---

## 0. Punto de partida

| Elemento | Estado |
|---|---|
| `circuit/smips.circ` | Placa resuelta: `Board`, `Memory` y `CPU` vacía con sus 10 pines y su apariencia. |
| Subcircuitos de la CPU | Ninguno. No existen `Instruction_Decoder`, `Control_Unit`, `Branch_Control`, `Datapath`, `Register_File` ni `ALU`. |
| `programs/` | 7 programas de ejemplo (`hello`, `array_sum`, `gcd`, `multiply`, `arithmetic`, `memory`, `branches`). |
| `tests/` | No existe (lo exige **R21**). |
| `images/` | Imágenes de memoria de los 4 programas de ejemplo (desactualizadas respecto a `programs/` si se editan). |
| `tools/` | `assemble.py`, `run_tests.py`, `build.py`, `Run.java`, `Ports.java`, `OpenCircuit.java`. |
| Git | Un único commit (`2666564 initial commit`), `origin` = `niitse34/…`, `upstream` = `UH-Matcom-AC/…` (material del profesor). |
| `informe.pdf`, `salida-tests.txt` | No existen (los exige **R23**). |

Los programas de ejemplo ya ejercitan casi todo el repertorio: `addi` (100 usos), `jal` (79), `add` (39), `beq`/`bne` (35), `lw`/`sw` (28), `lb`/`lbu`/`sb` (11), `slt`/`slti` (13), `sll`/`srl` (10), `and`/`or`/`andi`/`ori`/`lui` (9), `jr` (15), `move`, `li`, `la`, `nop`. Son una primera batería de aceptación.

---

## 1. Restricciones que gobiernan el diseño

| Requisito | Consecuencia práctica |
|---|---|
| **R1/R2** | Todo va dentro del subcircuito `CPU` del archivo entregado. No se toca `Board` ni `Memory`; no se renombran, reanchan, reorientan ni recrean pines, ni se edita la apariencia de `CPU`. |
| **R3** | Ningún reloj derivado: `CLK` llega directo a cada registro y al registro de estado. Nada de lógica en el camino del reloj. |
| **R4/R5** | `TTY_WE` y `MEM_WE` son salidas Moore de un solo estado, de modo que duran exactamente un flanco. |
| **R6** | Reset: `PC=0`, `$sp=0x3FFC`, `$gp=0x1800`, resto de registros 0, estado inicial, `MEM_WE=TTY_WE=HALT=0`. Se implementa con el `Clear` asíncrono de los registros (verificado: el registro de Logisim 5.0.0 tiene pin *Clear* asíncrono). |
| **R8–R11** | 23 instrucciones + `addu`/`addiu`; palabra ilegal ⇒ `HALT` sin escribir nada; `0x00000000` es `nop` legal. Se identifican solo por `op` y, si `op=0`, por `funct`. |
| **R12/R13** | Multiciclo, una instrucción a la vez, con `IR` durante todos los ciclos. |
| **R14** | Una sola ALU y **ningún sumador más**: `PC+4`, destino de salto y dirección de memoria son tres operaciones de ALU en ciclos distintos. Comparador de igualdad permitido en `Branch_Control`. |
| **R15** | Máquina de estados síncrona dentro de `Control_Unit`, con registro de estado + lógica combinacional. |
| **R16** | Seis subcircuitos obligatorios con nombres y jerarquía exactos (ver §5). |
| **R17** | Sin RAM ni ROM dentro de la CPU; `Register_File` con registros, multiplexores y decodificadores. |
| **R18–R20** | Si se usa VHDL: como máximo 2 de {`Register_File`, `ALU`, `Instruction_Decoder`}, puertos `std_logic*`, VHDL-2002, sintetizable, sin Questa si no se usa. |
| **R21–R23** | `tests/` propio con cobertura de la tabla de casos, `informe.pdf` ≤ 10 páginas, `salida-tests.txt`, entrega por GitHub. |

Criterios de evaluación a los que se apunta: corrección 40 %, pruebas propias 10 %, estructura 20 %, claridad 10 %, informe 10 %, defensa 10 %.

---

## 2. Entorno verificado en esta máquina

Comprobado ejecutando el arnés real, no por suposición:

| Recurso | Valor |
|---|---|
| Java | 25.0.5.0.3 (`java`, `javac`, `javap` en `C:\Program Files\Java\jdk-25.0.5.0.3\bin`) |
| Logisim Evolution | 5.0.0 en `C:\Program Files\logisim-evolution\app\logisim-evolution-5.0.0-all.jar` |
| MARS | `C:\Users\Naisy de la Caridad\Downloads\Mars4_5.jar` |
| Python | 3.14.7 |
| `LOGISIM_JAR`, `MARS_JAR` | No están definidas; hay que exportarlas en cada sesión. |

Resultados ya comprobados:

- `tools/Ports.java` abre `circuit/smips.circ` con el JAR de Logisim y lista los puertos de `Board`, `CPU` y `Memory`: el archivo es válido y el arnés de introspección funciona.
- `tools/Run.java` simula la placa vacía 100 ciclos y devuelve `RESULTADO … detenido=false`: el bucle de reloj, la RAM y el TTY funcionan sin interfaz gráfica interactiva.
- `python tools/assemble.py` falla **solo** por el directorio temporal: MARS no puede escribir en un directorio creado con `tempfile.mkdtemp` (ACL restrictiva), pero escribe sin problema en un directorio creado con `mkdir` dentro del repositorio. Solución verificada: usar un directorio de trabajo fijo del repo (`.work/`), no `tempfile`.
- Logisim escribe sus preferencias en el registro de Windows y el sandbox lo deniega (`SecurityException` en `AppPreferences`). Solución verificada: añadir una fábrica de preferencias en memoria al *classpath* y pasar `-Djava.util.prefs.PreferencesFactory=MemPrefsFactory`.
- No hay Questa, ni LaTeX, ni LibreOffice en `PATH`. Hay Microsoft Office instalado.
- El nombre de un script no debe coincidir con un módulo de la biblioteca estándar (un `bisect.py` de pruebas rompió `tempfile`/`random`).

Consecuencia: **el ciclo de verificación automática es viable en esta máquina** (ensamblar → simular → comparar con MARS), con dos ajustes locales del arnés que se describen en §6.

---

## 3. Decisiones de arquitectura

### D1. Sin VHDL (0 de 3 componentes)
Motivo: no hay Questa ni licencia; sin VHDL la simulación es mucho más rápida (decenas de ciclos/s con Questa frente a miles sin él) y se evitan R19/R20 por completo. El informe declara «ningún componente en VHDL».
Alternativa si se quisiera VHDL: `ALU` y `Instruction_Decoder`, que son los más mecánicos; implicaría instalar Questa + `open.sh`, `.vhd` por entidad y un orden de magnitud más de tiempo de prueba.

### D2. Multiciclo de 3 y 4 ciclos, 5 estados
`FETCH → DECODE → EXEC → (MEM) `, más `HALTED`. Tres ciclos para todo salvo `lw/lb/lbu/sw/sb`, que usan cuatro. Es el esquema clásico de multiciclo: fácil de dibujar en el informe, fácil de defender y dentro de la referencia de 3–5 ciclos de la guía.

### D3. Jerarquía obligatoria + tres subcircuitos auxiliares
`CPU` contiene los seis obligatorios; `Datapath` contiene `Register_File` y `ALU`. Auxiliares (permitidos por el enunciado «en cualquier nivel»): `Immediate_Extender` y `Memory_Interface` dentro de `Datapath`, `Syscall_Decoder` dentro de `Control_Unit`.

### D4. Una sola ALU, tres usos en ciclos distintos
- `FETCH`: `PC + 4` (ALU).
- `DECODE`: destino de rama `PC + (imm<<2)` (ALU), latcheado en `TARGET`.
- `EXEC`: operación de la instrucción, o dirección `R[rs] + imm` de `lw/sw/lb/lbu/sb` (ALU), latcheada en `MAR`.

El desplazamiento `imm<<2` se hace con un `Shifter` (permitido: «desplazador»), no con un sumador. `PC+4` nunca se calcula con un contador ni con un sumador aparte.

### D5. Reset asíncrono con `Clear` + carga de `$sp`/`$gp`
Todos los registros y el registro de estado llevan `RESET` al pin *Clear* asíncrono (R6 lo permite). `$sp` y `$gp` no pueden quedar a 0: en `Register_File` esos dos registros usan `D = RESET ? constante : WD` y `EN = RESET | escritura`, de modo que en el primer flanco con `RESET=1` toman `0x3FFC` y `0x1800`. Mientras `RESET=1`, `Control_Unit` fuerza `PCWrite=IRWrite=0` para que `PC` no avance.

### D6. Ruta de bytes en un subcircuito
`Memory_Interface` concentra: selección del byte de `MEM_RDATA` por `MAR[1:0]`, extensión con signo/cero (`lb`/`lbu`), palabra completa (`lw`), réplica del byte a los cuatro carriles y `BE = 1<<MAR[1:0]` para `sb`, `BE=1111` y `WDATA=B` para `sw`. La memoria es little-endian y ya aplica `BE`, así que la CPU solo replica (el README lo admite explícitamente).

### D7. `syscall` sin hardware extra
En `DECODE` los multiplexores de dirección de lectura del banco se conmutan: puerto 1 lee `$a0` (`rs=4`) y puerto 2 lee `$v0` (`rt=2`). Así `A=$a0`, `B=$v0` quedan latcheados. `Syscall_Decoder` compara `B[31:0]` con 10 y 11 usando solo compuertas (los 28 bits altos a cero, `B[3]=B[1]=1`, `B[0]` distingue 10 de 11). En `EXEC`: `TTY_WE=1` y `TTY_DATA=A[6:0]` para el servicio 11; para el 10 se pasa a `HALTED`. Cualquier otro valor no hace nada.

### D8. Construcción programática del circuito, con validación
No hay forma de operar la GUI de Logisim desde el agente, y dibujar a mano 32 registros, dos multiplexores de 32 vías y ~150 componentes no es verificable paso a paso. El `.circ` es XML y el propio repo ya lo genera programáticamente (`tools/build.py`). Por tanto: un generador construye la jerarquía y el cableado por túneles, y cada paso se valida cargando el archivo con Logisim (`Ports.java`) y simulándolo (`Run.java`). El archivo entregado sigue siendo `circuit/smips.circ`; el generador es solo una herramienta de construcción. La GUI se usa al final para revisar y anotar.

Salvaguardas: copia prístina del archivo (`git show HEAD:circuit/smips.circ`), nunca ejecutar `tools/build.py` (sobrescribe), y comparación automática del subárbol `CPU`/`Board`/`Memory` contra la copia base.

---

## 4. Microarquitectura

### 4.1 Diagrama de la ruta de datos

```text
                 +--------------------------------------------------------------+
   CLK,RST ----> | Control_Unit (FSM)   <- Instruction_Decoder <- IR[31:26],[5:0]|
                 +------+-------------------------------------------------------+
                        | señales de control
                        v
  PC --> [mux IorD] ----------------------> MEM_ADDR
   ^         ^
   |         +-- PC+4 (ALU en FETCH), TARGET (rama/j/jal), A (jr)  [mux PCSrc]
   |
   +-- PC + ALU(A,B,shamt) --+--> TARGET (DECODE, rama)
                             +--> MAR    (EXEC, load/store) --> [mux IorD]
                             +--> WD     (EXEC, ALU)  --> [mux WDSel] --> Register_File
                             +--> Zero --> Branch_Control --> PCWrite/PCSrc

  Register_File: RdAddr1/RdAddr2 ([mux Syscall] rs/rt o 4/2) --> RD1, RD2
                 RD1 --> A (DECODE)      RD2 --> B (DECODE)
                 WrAddr ([mux RegDst] rd/rt/31)  WrData ([mux WDSel] ALU/load/PC/imm<<16)
  B --> Memory_Interface --> MEM_WDATA, MEM_BE
  MEM_RDATA, MAR[1:0] --> Memory_Interface --> load data --> WDSel
  A[6:0] --> TTY_DATA
```

### 4.2 Registros del Datapath

| Registro | Ancho | Habilitación | Contenido |
|---|---|---|---|
| `PC` | 32 | `PCWrite` (Branch_Control) | dirección de la instrucción en curso |
| `IR` | 32 | `IRWrite` | instrucción en curso (R13) |
| `A` | 32 | `AWrite` (=DECODE) | `R[rs]` (o `$a0` en `syscall`) |
| `B` | 32 | `BWrite` (=DECODE) | `R[rt]` (o `$v0` en `syscall`); dato de `sw/sb` en `MEM` |
| `MAR` | 32 | `MARWrite` (=EXEC y load/store) | dirección efectiva de memoria |
| `TARGET` | 32 | `TargetWrite` (=DECODE y rama/j/jal) | destino de rama o de salto |
| `Register_File` | 32×32 | `RegWrite` | banco de registros |

No hay registro `ALUOUT`: todo consumidor de la ALU (PC, TARGET, MAR, banco) la lee en el mismo ciclo, que es lo correcto en un diseño multiciclo.

### 4.3 Multiplexores

| Mux | Entradas | Selector |
|---|---|---|
| `PCSrc` | ALU (PC+4), `TARGET`, `A` | `PCSrc[1:0]` |
| `IorD` | `PC`, `MAR` | `IorD` |
| `ALUSrcA` | `A`, `PC` | `ALUSrcA` |
| `ALUSrcB` | `B`, `EXT_IMM`, constante 4, `IMM_X4` | `ALUSrcB[1:0]` |
| `RegDst` | `IR[15:11]`, `IR[20:16]`, 31 | `RegDst[1:0]` |
| `WDSel` | ALU, dato de carga, `PC`, `EXT_IMM` (lui) | `WDSel[1:0]` |
| `RdAddr1` | `IR[25:21]`, 4 | `SvcAddr` |
| `RdAddr2` | `IR[20:16]`, 2 | `SvcAddr` |
| `WData` (store) | `B`, `{4{B[7:0]}}` | `StoreKind` |
| `BE` (store) | `1111`, `1<<MAR[1:0]` | `StoreKind` |

### 4.4 Señales de control

Salidas de `Control_Unit` hacia `Datapath`/`Branch_Control`:
`FetchPC`, `BranchReq`, `JumpReq`, `JrReq`, `TargetWrite`, `AWrite`, `BWrite`, `MARWrite`, `IorD`, `IRWrite`, `MemWrite`, `RegWrite`, `RegDst[1:0]`, `WDSel[1:0]`, `ALUSrcA`, `ALUSrcB[1:0]`, `ALUOp[2:0]`, `ExtMode[1:0]`, `LoadKind[1:0]`, `StoreKind`, `SvcAddr`, `TTY_WE`, `HALT`.

Entradas a `Control_Unit`: `CLK`, `RESET`, las nueve señales de clase del decodificador, `legal`, `ALUOp[2:0]`, `ExtMode[1:0]`, `BranchType[1:0]`, `JumpType[1:0]`, `ByteOp[1:0]`, `Svc[1:0]`.

### 4.5 Máquina de estados (R15)

Codificación one-hot de 5 bits: `FETCH=00001`, `DECODE=00010`, `EXEC=00100`, `MEM=01000`, `HALTED=10000`. Un solo registro de 5 biestables con `Clear=RESET`.

| Estado actual | Condición | Siguiente |
|---|---|---|
| `FETCH` | siempre | `DECODE` |
| `DECODE` | `legal` | `EXEC` |
| `DECODE` | `¬legal` (instrucción ilegal) | `HALTED` |
| `EXEC` | `load ∨ store` | `MEM` |
| `EXEC` | `syscall ∧ Svc=10` | `HALTED` |
| `EXEC` | resto (incluye `syscall` 11 y otros servicios) | `FETCH` |
| `MEM` | siempre | `FETCH` |
| `HALTED` | siempre | `HALTED` |

Ecuaciones de próximo estado (una por biestable one-hot, `halt_now = (DECODE∧¬legal) ∨ (EXEC∧is_syscall∧Svc10)`):

```text
FETCH'   = MEM ∨ (EXEC ∧ ¬load ∧ ¬store ∧ ¬halt_now)
DECODE'  = FETCH ∧ ¬halt_now
EXEC'    = DECODE ∧ legal
MEM'     = EXEC ∧ (load ∨ store) ∧ ¬halt_now
HALTED'  = HALTED ∨ halt_now
```

Nota para la defensa: cuando la instrucción es ilegal, el `PC` ya se incrementó en `FETCH` antes de poder saberlo; ocurre en cualquier diseño multiciclo y no altera el estado observable ni la salida comparada con MARS.

### 4.6 Tabla de control por estado

| Señal | FETCH | DECODE | EXEC | MEM | HALTED |
|---|---|---|---|---|---|
| `FetchPC` | 1 | 0 | 0 | 0 | 0 |
| `BranchReq` | 0 | 0 | rama | 0 | 0 |
| `JumpReq` / `JrReq` | 0 | 0 | j-jal / jr | 0 | 0 |
| `PCSrc` | 0 = ALU | x | 1 = TARGET (rama/j/jal), 2 = A (jr) | x | x |
| `IorD` | 0 = PC | x | 0 | 1 = MAR | x |
| `IRWrite` | 1 | 0 | 0 | 0 | 0 |
| `AWrite` / `BWrite` | 0 | 1 | 0 | 0 | 0 |
| `TargetWrite` | 0 | rama, j, jal | 0 | 0 | 0 |
| `MARWrite` | 0 | 0 | load, store | 0 | 0 |
| `MemWrite` | 0 | 0 | 0 | store | 0 |
| `RegWrite` | 0 | 0 | R, I, LUI, jal | load | 0 |
| `RegDst` | x | x | 0=rd (R), 1=rt (I/LUI), 2=31 (jal) | 1=rt | x |
| `WDSel` | x | x | 0=ALU (R/I), 3=EXT (lui), 2=PC (jal) | 1=carga | x |
| `ALUSrcA` | 1 = PC | 1 = PC (rama) | 0 = A | 0 | x |
| `ALUSrcB` | 2 = 4 | 3 = `IMM_X4` | 0 = B (R), 1 = `EXT_IMM` (I, load, store, rama) | x | x |
| `ALUOp` | ADD | ADD | el del decodificador (rama: SUB) | x | x |
| `SvcAddr` | 0 | `is_syscall` | 0 | 0 | 0 |
| `TTY_WE` | 0 | 0 | `is_syscall ∧ Svc=11` | 0 | 0 |
| `HALT` | 0 | 0 | 0 | 0 | 1 |

Todas las salidas son Moore salvo la decisión de `PCWrite`, que `Branch_Control` calcula combinacionalmente dentro del ciclo.

### 4.7 Ciclos por instrucción

| Clase | Ciclos | Secuencia |
|---|---|---|
| R (`add`, `addu`, `sub`, `and`, `or`, `slt`, `sll`, `srl`) | 3 | F, D, E |
| I (`addi`, `addiu`, `slti`, `andi`, `ori`) | 3 | F, D, E |
| `lui` | 3 | F, D, E |
| `beq`, `bne` | 3 | F, D, E |
| `j`, `jal`, `jr` | 3 | F, D, E |
| `syscall` | 3 | F, D, E |
| `lw`, `lb`, `lbu`, `sw`, `sb` | 4 | F, D, E, M |
| instrucción ilegal | 2 | F, D → `HALTED` |

Peor caso estimado para los programas entregados: ~600–3000 ciclos, muy por debajo del límite de 60 000 de `run_tests.py`.

### 4.8 `Instruction_Decoder`

Entradas: `OP = IR[31:26]`, `FUNCT = IR[5:0]`.
Implementación: dos decodificadores 6→64 (componente `Decoder`, `select=6`), uno por campo, y compuertas OR sobre las líneas seleccionadas. Sin RAM ni ROM (R17).

Salidas one-hot de clase (más `legal`): `is_r`, `is_ialu`, `is_load`, `is_store`, `is_branch`, `is_jump`, `is_jr`, `is_syscall`, `is_lui`; `legal = OR de todas`.
`ALUOp` (000 ADD, 001 SUB, 010 AND, 011 OR, 100 SLT, 101 SLL, 110 SRL), `ExtMode` (00 signo, 01 cero, 10 lui), `BranchType` (00 ninguna, 01 `beq`, 10 `bne`), `JumpType` (00 ninguno, 01 `j`, 10 `jal`, 11 `jr`), `ByteOp` (00 palabra, 01 `lb`, 10 `lbu`, 11 `sb`).

Las ecuaciones por bit se derivan de la tabla de §4.10 en el generador (una sola fuente de verdad), no a mano.

### 4.9 `ALU`

Entradas `A[31:0]`, `B[31:0]`, `Shamt[4:0]`, `ALUOp[2:0]`; salidas `R[31:0]`, `Zero` (NOR de los 32 bits).

| ALUOp | Operación | Implementación |
|---|---|---|
| 000 | `A + B` | `Adder` de 32 bits (el único sumador de la CPU) |
| 001 | `A - B` | `Subtractor` de 32 bits |
| 010 | `A & B` | compuertas AND |
| 011 | `A | B` | compuertas OR |
| 100 | `A <s B` | `Comparator` `mode=twosComplement` (salida *Less*) |
| 101 | `B << Shamt` | `Shifter` `shift=ll`, distancia 5 bits |
| 110 | `B >>l Shamt` | `Shifter` `shift=lr`, distancia 5 bits |

`Zero` es la salida de comparación contra cero del resultado, y es la que usa `Branch_Control`.

### 4.10 Tabla instrucción → señales

| Instrucción | op/funct | Clase | ALUOp | Ext | ByteOp | Rama | Salto | Ciclos |
|---|---|---|---|---|---|---|---|---|
| `add` | 00/20 | R | ADD | – | – | – | – | 3 |
| `addu` | 00/21 | R | ADD | – | – | – | – | 3 |
| `sub` | 00/22 | R | SUB | – | – | – | – | 3 |
| `and` | 00/24 | R | AND | – | – | – | – | 3 |
| `or` | 00/25 | R | OR | – | – | – | – | 3 |
| `slt` | 00/2A | R | SLT | – | – | – | – | 3 |
| `sll` | 00/00 | R | SLL | – | – | – | – | 3 |
| `srl` | 00/02 | R | SRL | – | – | – | – | 3 |
| `jr` | 00/08 | JR | – | – | – | – | JR | 3 |
| `syscall` | 00/0C | SYS | – | – | – | – | – | 3 |
| `addi` | 08 | I | ADD | signo | – | – | – | 3 |
| `addiu` | 09 | I | ADD | signo | – | – | – | 3 |
| `slti` | 0A | I | SLT | signo | – | – | – | 3 |
| `andi` | 0C | I | AND | cero | – | – | – | 3 |
| `ori` | 0D | I | OR | cero | – | – | – | 3 |
| `lui` | 0F | LUI | – | lui | – | – | – | 3 |
| `lb` | 20 | LOAD | ADD | signo | lb | – | – | 4 |
| `lw` | 23 | LOAD | ADD | signo | palabra | – | – | 4 |
| `lbu` | 24 | LOAD | ADD | signo | lbu | – | – | 4 |
| `sb` | 28 | STORE | ADD | signo | sb | – | – | 4 |
| `sw` | 2B | STORE | ADD | signo | palabra | – | – | 4 |
| `beq` | 04 | BRANCH | SUB | signo | – | beq | – | 3 |
| `bne` | 05 | BRANCH | SUB | signo | – | bne | – | 3 |
| `j` | 02 | JUMP | – | – | – | – | j | 3 |
| `jal` | 03 | JUMP | – | – | – | – | jal | 3 |

`nop` (`0x00000000`) cae en la fila de `sll` y no escribe nada porque `RegDst` apunta a `$0`.

### 4.11 `Branch_Control`

Entradas: `FetchPC`, `BranchReq`, `JumpReq`, `JrReq`, `BranchType[1:0]`, `Zero`.
Salidas: `PCWrite`, `PCSrc[1:0]`, `Taken`.

```text
Taken   = (BranchType=beq ∧ Zero) ∨ (BranchType=bne ∧ ¬Zero)
PCWrite = FetchPC ∨ JumpReq ∨ JrReq ∨ (BranchReq ∧ Taken)
PCSrc   = FetchPC ? 0 (ALU) : JrReq ? 2 (A) : 1 (TARGET)
```

### 4.12 `Register_File` y reset

- 32 registros de 32 bits (`Register`, `width=32`, `trigger=rising`, `Clear=RESET`).
- Dos puertos de lectura: `Multiplexer` de 32 entradas (`select=5`, `width=32`) por puerto.
- Escritura: `Decoder` `select=5` habilitado por `RegWrite`; la línea 0 (`$0`) se deja desconectada, de modo que `$0` nunca se escribe.
- `$zero` siempre 0 (nunca habilitado y `Clear` en reset).
- `$sp` (29) y `$gp` (28): `D = RESET ? constante : WD`, `EN = RESET ∨ escritura`, con constantes `0x3FFC` y `0x1800`.
- Reset de los otros 30 registros por `Clear` asíncrono.

### 4.13 `Immediate_Extender` y `Memory_Interface`

- `Immediate_Extender`: `Imm[15:0]` → `EXT_IMM[31:0]` (signo / cero / `{imm, 16'h0}`) y `IMM_X4 = EXT_IMM << 2` con un `Shifter` de distancia 2.
- `Memory_Interface`: `MEM_RDATA`, `MAR[1:0]`, `LoadKind`, `StoreKind`, `B` → `LoadData` (palabra o byte extendido), `MEM_WDATA` (`B` o `{4{B[7:0]}}`), `MEM_BE` (`1111` o `1<<MAR[1:0]`).

---

## 5. Subcircuitos y pines

Jerarquía exigida por R16:

```text
CPU
├── Instruction_Decoder        (combinacional)
├── Control_Unit               (FSM)
│   └── Syscall_Decoder        (auxiliar)
├── Branch_Control             (combinacional)
└── Datapath
    ├── Register_File
    ├── ALU
    ├── Immediate_Extender     (auxiliar)
    └── Memory_Interface       (auxiliar)
```

| Subcircuito | Entradas | Salidas |
|---|---|---|
| `Instruction_Decoder` | `OP[5:0]`, `FUNCT[5:0]` | `is_r`, `is_ialu`, `is_load`, `is_store`, `is_branch`, `is_jump`, `is_jr`, `is_syscall`, `is_lui`, `legal`, `ALUOp[2:0]`, `ExtMode[1:0]`, `BranchType[1:0]`, `JumpType[1:0]`, `ByteOp[1:0]` |
| `Control_Unit` | `CLK`, `RESET`, clases, `legal`, `ALUOp[2:0]`, `ExtMode[1:0]`, `BranchType[1:0]`, `JumpType[1:0]`, `ByteOp[1:0]`, `Svc[1:0]` | todas las de §4.4 |
| `Branch_Control` | `FetchPC`, `BranchReq`, `JumpReq`, `JrReq`, `BranchType[1:0]`, `Zero` | `PCWrite`, `PCSrc[1:0]`, `Taken` |
| `Datapath` | `CLK`, `RESET`, `MEM_RDATA[31:0]` + control | `MEM_ADDR[31:0]`, `MEM_WDATA[31:0]`, `MEM_BE[3:0]`, `OP[5:0]`, `FUNCT[5:0]`, `A0[6:0]`, `Zero` |
| `Register_File` | `CLK`, `RESET`, `RdAddr1[4:0]`, `RdAddr2[4:0]`, `WrAddr[4:0]`, `WrData[31:0]`, `WrEnable` | `RdData1[31:0]`, `RdData2[31:0]` |
| `ALU` | `A[31:0]`, `B[31:0]`, `Shamt[4:0]`, `ALUOp[2:0]` | `R[31:0]`, `Zero` |

En `CPU` los pines de la placa se conectan por túneles con los nombres exactos del entregable (`CLK`, `RESET`, `MEM_RDATA`, `MEM_ADDR`, `MEM_WDATA`, `MEM_BE`, `MEM_WE`, `TTY_DATA`, `TTY_WE`, `HALT`). `MEM_WE`, `TTY_WE` y `HALT` salen de `Control_Unit`; `MEM_ADDR`, `MEM_WDATA`, `MEM_BE` y `TTY_DATA` del `Datapath`.

---

## 6. Herramientas: qué hay que añadir

| Herramienta | Función |
|---|---|
| `tools/MemPrefsFactory.java` | Fábrica de preferencias en memoria para poder cargar Logisim sin registro de Windows. Ya probada. |
| `tools/ListAttrs.java` | Vuelca nombre XML, valor por defecto y cadenas aceptadas de cada atributo de cada componente. Ya probado: es la fuente de verdad del Anexo A. |
| `tools/gen_cpu.py` | Genera/actualiza la jerarquía y el cableado de la CPU en `circuit/smips.circ` sin tocar `Board`, `Memory` ni la apariencia de `CPU`. Verifica los pines contra la copia base antes y después. |
| `tools/SimVectors.java` | Carga un circuito cualquiera con pines, aplica vectores de entrada y compara con los esperados (pruebas de `ALU`, `Register_File`, `Instruction_Decoder`). |
| `tools/check_cpu.py` | Auditoría estática de R2/R3/R14/R16/R17 sobre el `.circ`. |
| `tools/run_local.py` (o `.ps1`) | Exporta `LOGISIM_JAR`, `MARS_JAR`, `TEMP` al directorio de trabajo y lanza `assemble.py`/`run_tests.py` con la fábrica de preferencias. |
| `.work/` | Directorio de trabajo de las herramientas (ignorado por git; **no** usar `tempfile`, ver §2). |

Ajuste mínimo del arnés entregado: que `assemble.py` y `run_tests.py` usen `.work/` en lugar de `tempfile`, y que la invocación de Java incluya la fábrica de preferencias. No se toca `circuit/smips.circ` desde aquí salvo por `gen_cpu.py`.

---

## 7. Fases, entregables y criterios de aceptación

### F0. Red de seguridad y línea base (≈1 h)
- Guardar copia prístina: `git show HEAD:circuit/smips.circ > .cache/smips-base.circ`.
- Añadir `MemPrefsFactory.java`, `ListAttrs.java` y el lanzador local; ajustar el directorio de trabajo de `assemble.py`/`run_tests.py`.
- **Aceptación**: `Ports.java` carga `smips.circ`; `Run.java` simula la placa vacía 100 ciclos; `python tools/assemble.py programs/hello.asm` genera `images/hello.hex`; `python tools/run_tests.py programs/hello.asm` falla solo porque la CPU no hace nada (línea base documentada).

### F1. Esqueleto de la jerarquía (≈2 h)
- `gen_cpu.py` crea los seis subcircuitos + auxiliares con sus pines y apariencia (mismo estilo que `board`/`Memory`).
- **Aceptación**: el archivo carga; existen los seis con su jerarquía; `Board` y `Memory` idénticos byte a byte al original; la apariencia y los pines de `CPU` no cambian (comparación XML).
- **Riesgo**: un atributo XML inválido hace que Logisim **rechace el archivo completo**; se valida tras cada subcircuito añadido y se conserva una copia previa.

### F2. Hojas: `Register_File`, `ALU`, `Instruction_Decoder` (≈5 h)
- Banco con 32 registros, dos mux de 32 vías, decodificador de escritura, `$zero`, reset y valores iniciales de `$sp`/`$gp`.
- ALU con las 7 operaciones y `Zero`.
- Decodificador con las dos tablas 6→64 y las ecuaciones derivadas de §4.10.
- `SimVectors.java` con vectores: ALU (7 operaciones × casos límite), banco (escritura/lectura/`$0`/reset), decodificador (todas las `op` de 0 a 63 y todos los `funct` con `op=0`).
- **Aceptación**: 100 % de vectores correctos, incluida la detección de las instrucciones ilegales y el decodificado de `0x00000000` como `sll` legal.

### F3. `Datapath`, `Control_Unit`, `Branch_Control` y CPU conectada (≈8 h)
- Ruta de datos completa con túneles, tabla de control y FSM one-hot.
- **Aceptación**: `programs/hello.asm` imprime `Hola, S-MIPS`, enciende `Halt` y termina antes de 200 ciclos; la traza (`Run.java` con `traza=1`) muestra `MEM_ADDR` recorriendo `0x0000, 0x0004, …`.

### F4. Repertorio completo (≈6 h)
- Depurar con los 7 programas de `programs/`.
- **Aceptación**: `python tools/run_tests.py` con 7/7 correctos.

### F5. Pruebas propias (≈4 h)
- `tests/` según §9, con la tabla de cobertura.
- **Aceptación**: `run_tests.py` 12/12 correctos y `salida-tests.txt` generado.

### F6. Estructura, claridad e informe (≈5 h)
- `check_cpu.py` verde: R2, R3, R6, R10, R14, R16, R17.
- Etiquetas y textos explicativos en cada subcircuito (10 % de claridad).
- `informe.pdf` ≤ 10 páginas con las 8 secciones de la guía; `README.md` actualizado con la implementación.
- **Aceptación**: revisión del circuito en la GUI de Logisim (abrir, simular `hello` a mano), informe coherente con la tabla de control del circuito.

### F7. Entrega
- `git tag` de la versión entregada, repositorio con `circuit/smips.circ`, `tests/`, `informe.pdf`, `salida-tests.txt`.
- Confirmar visibilidad del repo (o dar acceso a la cuenta del profesor).

---

## 8. Verificación

Cuatro niveles, de más barato a más caro:

1. **Estática** (`check_cpu.py`): los 10 pines de `CPU` conservan nombre, ancho y sentido; apariencia de `CPU` sin cambios; `Board`/`Memory` sin cambios; existen los seis subcircuitos con la jerarquía; no hay `RAM`/`ROM` dentro de `CPU`; los únicos `Adder`/`Subtractor` están en `ALU`; ningún componente de reloj salvo los pines.
2. **Vectores por módulo** (`SimVectors.java`): ALU, banco y decodificador exhaustivos o por clases de equivalencia.
3. **Programas completos** (`run_tests.py`): salida del TTY comparada con MARS, 7 programas entregados + 5 propios.
4. **Presupuesto**: `detenido=true` y ciclos < 60 000 en todos; se registran los ciclos de cada programa para el informe.

Comandos (Windows, verificados salvo los ajustes de F0):

```powershell
$env:LOGISIM_JAR = 'C:\Program Files\logisim-evolution\app\logisim-evolution-5.0.0-all.jar'
$env:MARS_JAR    = 'C:\Users\Naisy de la Caridad\Downloads\Mars4_5.jar'
$env:TEMP = "$PWD\.work"; $env:TMP = $env:TEMP
python tools\assemble.py programs\hello.asm
python tools\run_tests.py
python tools\run_tests.py programs\memory.asm
```

---

## 9. `tests/` propios (R21)

Cinco programas, cada uno con cabecera de comentarios que enumera lo que cubre, salida de valores calculados en hexadecimal o decimal y terminación con `syscall 10`, dentro de 12×48 caracteres:

| Programa | Contenido | Filas de la tabla de casos |
|---|---|---|
| `t-arith.asm` | `add`/`sub` con positivos y negativos; `and`/`or` con bits altos; `slt` con resultado 0 y 1 y con negativos (signo vs sin signo); `sll`/`srl` con `shamt=0` y ≠0, `srl` sobre negativo | add, sub, and, or, slt, sll, srl |
| `t-imm.asm` | `addi` con inmediato negativo; `addiu` y `addu` vía `li` y `move`; `andi`/`ori` con bit 15 a 1; `lui` con bit 15 a 1; `slti` con 1/0 y con negativo | addi, addiu, addu, andi, ori, lui, slti |
| `t-mem.asm` | `lw`/`sw` con desplazamiento positivo y negativo; `lb`/`lbu` sobre byte con bit 7 a 1 en dos carriles; `sb` en los cuatro carriles comprobando después con `lw` | lw, sw, lb, lbu, sb |
| `t-flow.asm` | `beq`/`bne` tomados y no tomados, un salto hacia atrás, `j`, `jal`/`jr` con procedimiento no hoja y pila, escritura en `$zero` y comprobación | beq, bne, j, jal, jr, $zero |
| `t-sys.asm` | servicios 11 y 10, carácter especial (`\n`), y verificación de que un servicio desconocido no altera nada | syscall |

El informe incluirá la matriz fila → programa.

---

## 10. Informe y entrega

`informe.pdf` (≤ 10 páginas), en el orden que exige la guía:

1. Nombre y componentes en VHDL (ninguno, con la justificación de D1).
2. Diagrama de la ruta de datos con nombres de señales de control.
3. Diagrama o tabla de la FSM (estados, transiciones, condiciones) — §4.5.
4. Tabla de señales de control por estado — §4.6.
5. Codificación de ALU y del decodificador — §4.8/§4.9.
6. Ciclos por clase de instrucción — §4.7.
7. Cobertura de `tests/` — §9.
8. Resultados de `run_tests.py` y limitaciones conocidas.

Producción: documento DOCX generado con `python-docx` (disponible) y exportado a PDF con Word (Office está instalado) o con el flujo *office* del harness; si el diagrama se quiere vectorial, se puede generar un SVG con un script y embeberlo. Las tablas 3–6 se generan a partir de las mismas tablas de datos que usa `gen_cpu.py`, para que informe y circuito no se desincronicen.

---

## 11. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
|---|---|---|
| Un atributo XML mal escrito hace que Logisim rechace el archivo | Alto | Validar tras cada paso con `Ports.java`; Anexo A como referencia; copia previa versionada |
| Violar R2 (pines o apariencia de `CPU`) | Entrega no evaluable | `check_cpu.py` compara contra la copia base; nunca ejecutar `build.py` |
| Reset de `$sp`/`$gp` incorrecto | Programas fallan desde la primera instrucción | `memory.asm` imprime `$gp` y `$sp`; verificación explícita |
| Ruta de bytes (`lb`/`lbu`/`sb`) mal alineada | `memory.asm` falla | `Memory_Interface` aislado y con vectores propios |
| `slt` con negativos y desbordamiento | Filas de la tabla de casos | `Comparator` en complemento a 2 + casos límite |
| `TTY_WE`/`MEM_WE` con más de un flanco | R4/R5 | Salidas Moore de un solo estado; la traza de `Run.java` lo confirma |
| Logisim 5.0.0 sobre Java 25 (la guía pide 21) | Inestabilidad de la GUI | Ya carga y simula; si aparece un fallo, instalar JDK 21 y usarlo solo para el arnés |
| Sin Questa (si se eligiera VHDL) | No se puede simular | D1: sin VHDL |
| `informe.pdf` sin LaTeX ni LibreOffice | Falta un entregable | Word instalado + `python-docx`; verificar la exportación en F6 |
| Tiempo de dibujo manual del banco de registros | Retraso | Generación programática + `SimVectors` |

---

## 12. Decisiones abiertas (confirmar antes de F1)

1. **VHDL**: ¿se confirma 0 componentes en VHDL (recomendado) o se quiere usar el cupo de 1–2 y montar Questa?
2. **Construcción**: ¿se confirma la generación programática del `.circ` con revisión final en la GUI (recomendado), o se prefiere dibujar a mano y usar el generador solo para el esqueleto?
3. **Ciclos**: ¿se acepta el esquema 3/4 ciclos, o se prefiere un multiciclo clásico de 4/5 para que el informe siga el esquema del aula?
4. **Informe**: ¿DOCX→PDF con Word, o se intenta instalar LaTeX para reutilizar el estilo de `guide.tex`?

---

## Anexo A. Atributos XML de Logisim 5.0.0 verificados

Obtenidos con `ListAttrs` sobre el JAR instalado. Son los que hay que escribir en el `.circ`; un nombre o valor no aceptado invalida el archivo entero.

| Componente | Atributos (valor por defecto) |
|---|---|
| `Pin` | `label`, `width`, `type` (`input`/`output`), `facing`, `appearance`, `labelfont`, `labelloc` |
| `Tunnel` | `label`, `width`, `facing`, `labelfont` |
| `Text` | `text`, `font` |
| `Splitter` | `incoming`, `fanout`, `appear` (`left`/`center`/`right`), `spacing`, `facing`, `bit0`…`bit31` (índice de carril o `none`) |
| `Multiplexer` | `select` (bits de selección 1–8), `width` (bits de datos), `size` (ancho dibujado, p. ej. `40`), `selloc`, `facing`, `enable` (`true`/`false`), `disabled` |
| `Decoder` | `select` (1–8), `enable` (`true` por defecto), `tristate`, `selloc`, `facing` |
| `Register` | `width`, `trigger` (`rising`), `label`, `labelloc`, `labelfont`, `appearance` (`logisim_evolution`/`classic`), `showInTab` |
| `Adder` / `Subtractor` | `width` |
| `Comparator` | `width`, `mode` (`twosComplement` o `unsigned`) |
| `Shifter` | `width`, `shift` (`ll` lógico izquierda, `lr` lógico derecha, …), `dummy` (bits de la distancia) |
| `Bit Extender` | `in_width`, `out_width`, `type` (`sign`, `zero`, `input`) |
| `RAM` | `addrWidth`, `dataWidth`, `databus` (`bibus`), `byteenables` (`byteEnables`), `asyncread`, `appearance`, `label`, `type` (`nonvolatile`) |

Pines del registro observados en la práctica: `Q` (salida), `D`, `Reloj`, `Clear` (asíncrono, activo a 1), `Enable`.

## Anexo B. Hallazgos operativos del arnés

- Logisim necesita Java con `java.util.prefs` funcional; en esta máquina el registro está denegado → `-Djava.util.prefs.PreferencesFactory=MemPrefsFactory` con la clase en el *classpath*.
- `tempfile.mkdtemp` crea directorios donde MARS (Java) no puede escribir; `Path.mkdir()` dentro del repositorio sí funciona. Usar `.work/` y `TEMP`/`TMP` apuntando ahí. Peor aún: esos directorios de `mkdtemp` quedan luego inaccesibles (incluso para `icacls`) y solo se pueden borrar desde fuera del sandbox; es un motivo más para no usar `tempfile` en el arnés.
- `java`/`javac` están en el `PATH`, pero `javap` no: usar `C:\Program Files\Java\jdk-25.0.5.0.3\bin\javap.exe`.
- La compilación al vuelo (`java Archivo.java`) sirve para ejecutar `Ports.java` y `Run.java` sin compilar aparte.
- `Run.java` sin `-Djava.awt.headless=true` (crea un `Frame` invisible); con *headless* falla.
- No bautizar scripts con nombres de módulos de la biblioteca estándar (`bisect.py` rompió `tempfile`).
