# Task: Unidades imperiales (peso y altura)

## Metadata

| Campo | Valor |
|--------|--------|
| **Tipo** | Feature |
| **Origen** | `docs/ROADMAP.md` — Backlog: *Imperial units support (lbs) for weight and profile* (ampliado a **altura + peso** por decisión de producto) |
| **REQ** | Registrar e implementar: **`REQ-PROF-003`** (preferencia de unidades, perfil, registro, mailers con métricas corporales); **`REQ-WGT-004`** (registro e historial de peso en unidades de UI); extender criterios de **`REQ-RPT-003`** (eje/tooltip del gráfico de peso). |
| **Arquitectura** | Alineado con `docs/core/SYSTEM_ARCHITECTURE.md`: BD canónica **kg + cm**; conversiones en capa de aplicación / presentación; I18n `es`/`en`; trazabilidad `# [REQ-…]` |

## Decision log

| Fecha | Decisión |
|--------|-----------|
| 2026-04-19 | **Alcance:** soporte **peso (lbs)** y **altura** en unidades imperiales (p. ej. pies/pulgadas), no solo lbs. |
| 2026-04-19 | **Persistencia:** seguir almacenando **solo** `weight_kg`, `height_cm` (y columnas derivadas existentes como `bmi`); **convertir al mostrar y al aceptar entrada** según preferencia del usuario. |
| 2026-04-19 | **Default:** nuevos y existentes sin tocar el ajuste → **`metric`** (comportamiento actual). |
| 2026-04-19 | **Preferencia:** **un solo** control a nivel usuario (peso + altura + vistas derivadas comparten el mismo sistema). |
| 2026-04-19 | **Alcance imperial:** **US customary** — **lbs** y **pies/pulgadas**; **fuera de alcance** stone/UK y otros sistemas. |
| 2026-04-19 | **Precisión de pantalla:** ver sección *Convención cotidiana (US)* abajo — **lb con 1 decimal**; **pies + pulgadas enteras** (sin medias pulgadas salvo que más adelante se pida). |
| 2026-04-19 | **Mailers:** cualquier correo que muestre peso y/o altura debe usar la **misma preferencia de unidades** que el usuario (misma fuente de verdad que la web). |

## Convención cotidiana (US) — precisión en UI

En uso **habitual** en Estados Unidos:

- **Peso (lb):** en conversación mucha gente redondea a **libras enteras** (“I weigh 165”), pero **básculas digitales y apps de salud** enseñan casi siempre **décimas de libra** (p. ej. `165.4 lb`). Para un producto de seguimiento de peso, **1 decimal en lb** coincide con la expectativa más frecuente y evita que el gráfico/historial se vea “saltando” en conversiones desde kg.
- **Altura (ft / in):** lo cotidiano es **pulgadas enteras** (“5 foot 7”). Medias pulgadas o fracciones son raras en autoinforme; formularios suelen ser **ft entero + in entero (0–11)**.

**Métrico (para simetría en la misma feature):** mantener coherencia con lo que ya tenga la app; lo habitual en apps es **kg con 1 decimal** (o 2 si ya está así) y **cm enteros** — alinear con el redondeo de **solo presentación**, no tocar precisión canónica en BD.

## Domain model

### Approved types (locked — Step 3.0)

| Concepto | Nombre / ubicación | Contrato |
|----------|-------------------|----------|
| Preferencia de unidades | **`BodyUnitSystem`** (enum o columna con vocabulario cerrado) | Valores **`metric`** \| **`imperial_us`** únicamente. |
| Conversión y formato canónico ↔ UI | **`BodyMetrics`** (módulo o servicios bajo `app/services/`, alineado a `SYSTEM_ARCHITECTURE.md`) | Constantes explícitas para factores kg↔lb y cm↔pies/pulgadas; **`BigDecimal`** para cálculos; redondeo **solo** en capa de presentación (lb **1** decimal; pulgadas **enteras**). |
| Entrada de formulario | **`HeightInput`**, **`WeightInput`** (capa formulario) | Parseo (incl. ft + in compuestos) → **`cm`** / **`kg`** canónicos antes de asignar a ActiveRecord. |

**Estado:** aprobado por producto el **2026-04-19**; no introducir primitivos sueltos para estos conceptos en dominio ni en firmas públicas nuevas.

### User (extensión)

- **Responsabilidad:** además del perfil actual, expresa **preferencia de sistema de unidades corporales** para UI y formularios.
- **Invariantes:**
  - Los valores canónicos en BD siguen siendo **kg** y **cm** en `users` y `weight_logs`; ningún cálculo de BMI o reconciliación de `current_weight_kg` debe depender de unidades de visualización.
  - La preferencia de unidades **no** reescribe filas históricas: solo afecta interpretación de entrada y formato de salida.
- **Value objects / tipos:** usar los nombres y contratos de la tabla **Approved types** arriba.

### WeightLog

- **Invariantes:** `weight_kg` y `height_cm` permanecen como hoy; la preferencia del usuario solo cambia cómo se muestran en historial y formularios de edición si los hubiera.

### Vistas / Informes

- **Gráfico de peso (`REQ-RPT-003`):** eje Y y tooltips deben respetar la misma preferencia (lbs vs kg), manteniendo la serie basada en datos canónicos.

## Riesgos y notas

- **Redondeo:** reglas fijadas en *Convención cotidiana (US)*; al aceptar entrada imperial, convertir a canónico sin acumular error de doble redondeo respecto a BMI.
- **Altura imperial:** UX típica ft + in separados; validar rangos humanos razonables tras conversión a cm.
- **Usuarios existentes:** default recomendado **`metric`** para no cambiar comportamiento actual hasta que elijan imperial en perfil.
- **Registro / onboarding:** si el flujo de alta solo pide cm/kg hoy, añadir controles imperiales coherentes o selector global de unidades antes de los campos.

## Casos límite, rincones oscuros y errores comunes

| Tema | Qué vigilar |
|------|----------------|
| **Doble conversión** | Convertir para mostrar y **volver** a interpretar mal al guardar (p. ej. tratar un valor ya en kg como si fuera lb) corrompe datos. Flujo: entrada en unidades UI → **una** normalización a canónico (kg/cm) antes de validar y persistir. |
| **Cambio de preferencia en vivo** | Al pasar métrico ↔ imperial, los datos en BD no cambian; solo etiquetas y campos de formulario. No migrar filas; refrescar pantalla coherente (perfil, registro de peso, historial, informe). |
| **Redondeo vs exactitud** | Mantener cálculos en **`BigDecimal`** alineado al dominio; **redondear solo para display** (lb **1 decimal**, pulgadas **enteras**) sin que el canónico en BD dependa del redondeo de pantalla. |
| **Altura ft/in** | `12 in = 1 ft`; entradas como `5 ft 12 in` = 6 ft; validar **después** de convertir a cm contra los mismos límites que hoy tiene `height_cm`. Evitar pérdida por solo guardar “pies” redondeados. |
| **BMI** | Sigue siendo escalar **sin unidad**; no hace falta “BMI imperial”. Asegurar que el **peso y altura usados en la fórmula** sigan siendo los canónicos kg/cm, no valores redondeados de UI. |
| **Snapshots en `WeightLog`** | `height_cm` en cada fila es histórico; al listar, mostrar ese snapshot convertido a la preferencia **actual** del usuario (consistente con “solo afecta presentación”). |
| **Gráfico / SVG / Informes** | Eje Y, leyenda y tooltip deben usar la misma preferencia; la serie interna sigue en kg. Cuidado con saltos si algún día se mezclan caches. |
| **I18n** | Sufijos `kg`/`cm` vs `lb`/`ft`/`in` y copy en `es`/`en`; no hardcodear strings (regla de arquitectura). |
| **Validaciones duplicadas** | No copiar rangos máx/mín solo en imperial; **un** rango canónico y mensajes de error que puedan mostrarse en la unidad activa. |
| **Mailers / notificaciones** | **Obligatorio:** alinear con **`User` preferencia de unidades**; inventariar vistas de mailer que incluyan peso/altura y cubrirlas en pruebas. |
| **Pruebas** | System/request: alternar preferencia y comprobar que el mismo registro en BD se lee con números convertidos esperados; regresión en BMI y `ReconcileUserCurrentStats`. |

## Alcance fuera de esta feature (explícito)

- **Import/export/API públicos:** no bloqueante; contrato interno sigue siendo **kg/cm** en BD. Documentar en SPEC brevemente.
- **Peso en “stone” u otras variantes UK:** explícitamente no.

---

**Estado:** **SPEC CERRADO** — implementación solo vía skill `start-task` (TDD estricto). El plan siguiente es normativo.

<implementation_plan>
  <classification>Feature</classification>
  <mandate>TDD: no implementar lógica de producción sin un ejemplo RSpec que haya fallado primero para ese comportamiento; mantener `docs/core/SYSTEM_ARCHITECTURE.md` (servicios bajo `app/services/`, I18n, sin strings duros).</mandate>

  <step id="1" status="complete">Escribir **fallando** especificaciones de unidad para **`BodyMetrics::*`** (o nombre alineado al repo): conversión **kg↔lb** y **cm↔ft/in** con constantes explícitas, redondeo **solo** según reglas de presentación (lb **1** decimal; pulgadas **enteras**; sin doble redondeo que rompa invariantes frente a BMI). Incluir casos límite: `12 in` roll-up a pies, valores canónicos ya existentes en fixtures.</step>

  <step id="2" status="complete">Implementar el módulo/servicio de conversión hasta **verde**; mantener cálculos BMI y reconciliación (`WeightLogs::ReconcileUserCurrentStats`, etc.) basados **únicamente** en columnas canónicas **kg/cm**.</step>

  <step id="3" status="complete">Escribir **fallando** ejemplos de modelo/migración: columna persistida en **`users`** (p. ej. `body_unit_system` o equivalente) con valores **`metric` | `imperial_us`**, **default `metric`**, **NOT NULL**; validación de vocabulario cerrado. Aplicar migración y modelo hasta **verde**.</step>

  <step id="4" status="complete">Actualizar **`docs/core/SPEC.md`** (y glosario si aplica) con **`REQ-PROF-003`**, **`REQ-WGT-004`**, y criterios añadidos a **`REQ-RPT-003`**; enlazar **`docs/core/SCHEMA_REFERENCE.md`** / **`DATA_FLOW_MAP.md`** si el repo los mantiene sincronizados tras el cambio de esquema.</step>

  <step id="5" status="complete">Escribir **fallando** specs de **request o sistema** para **perfil y alta de usuario**: selector único de unidades; campos de peso/altura en **métrico o imperial US** según preferencia; persistencia siempre **kg/cm**; mensajes y `aria-*` coherentes con validaciones existentes sobre `height_cm` tras conversión.</step>

  <step id="6" status="complete">Implementar formularios, strong params, y vistas hasta **verde**; strings vía **I18n** (`es` / `en`) para etiquetas y unidades.</step>

  <step id="7" status="complete">Escribir **fallando** specs para **registro de peso** (`LogWeightService` / controlador según el código actual) e **`WeightLogs::HistoryPage`**: entrada en lb o kg según usuario; listado con snapshot de altura y peso formateados según preferencia **actual**; borrar/reconciliar sin regresión.</step>

  <step id="8" status="complete">Implementar capa de presentación y parámetros hasta **verde**; reutilizar el mismo formateador/helper que perfil para evitar divergencia.</step>

  <step id="9" status="complete">Escribir **fallando** spec para **Informes / gráfico de peso** (`WeightLogs::ChartSeries` + vista SVG): eje Y, leyenda y tooltip en unidades del usuario; serie interna sigue derivada de **`weight_kg`**. Implementar hasta **verde**.</step>

  <step id="10" status="complete">**Mailers:** auditar `app/mailers` y vistas asociadas; cualquier texto futuro o actual que muestre peso/altura debe obtener formato vía helper que lea la preferencia del **`User`**. Escribir **fallando** ejemplo (mailer spec o preview contract) donde aplique; si hoy no hay contenido afectado, dejar spec de **regresión** (p. ej. helper) que falle si se introduce un mailer con métricas sin pasar por el formateador.</step>

  <step id="11" status="pending">Pase final: suite completa en verde; revisar **`# [REQ-…]`** en archivos tocados según `.cursor/rules/spec-req-traceability.mdc`; marcar ítem de backlog en **`docs/ROADMAP.md`** cuando el branch esté listo (fuera de este documento si usas `finish-branch`).</step>
</implementation_plan>

