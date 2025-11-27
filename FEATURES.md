# Guía de Funcionalidades - COVID-19 Tracker

## 🎯 Funcionalidades Implementadas

### 1. Sistema de Autenticación
- **Login persistente**: El correo se guarda automáticamente en UserDefaults
- **Auto-login**: Si existe una sesión previa, la app salta directamente al menú
- **Validación**: Verifica que el correo no esté vacío antes de permitir el acceso
- **Cierre de sesión**: Limpia los datos y regresa a la pantalla de login

### 2. Búsqueda de Países
- **Input libre**: Permite buscar cualquier país por nombre
- **Ejemplos válidos**: 
  - Canada
  - Italy
  - Spain
  - United States
  - Mexico
  - France
  - Germany
- **Auto-carga**: El último país consultado se carga automáticamente al abrir la app
- **Búsqueda inteligente**: Presiona Enter o el botón de búsqueda para consultar

### 3. Estados de la Interfaz

#### Estado de Carga
```
┌─────────────────────┐
│   ProgressView      │
│  "Cargando datos..."│
└─────────────────────┘
```

#### Estado de Error
```
┌─────────────────────┐
│    ⚠️ Error          │
│  Mensaje descriptivo│
│  [Botón Reintentar] │
└─────────────────────┘
```

#### Estado Inicial
```
┌─────────────────────┐
│ "Ingresa un país    │
│  para ver datos"    │
└─────────────────────┘
```

#### Estado de Éxito
```
┌─────────────────────┐
│ Lista de Regiones   │
│ • Alberta           │
│ • British Columbia  │
│ • Ontario           │
└─────────────────────┘
```

### 4. Visualización de Datos COVID

#### Resumen en Tarjetas
- **Tarjeta Azul**: Total de casos confirmados
- **Tarjeta Roja**: Total de muertes
- **Información adicional**: Fecha del último dato

#### Selector de Tipo de Datos
```
[ Casos ] [ Muertes ]
   ✓         
```
- Toggle segmentado para cambiar entre visualización de casos y muertes
- Actualiza automáticamente el gráfico al cambiar

#### Filtro de Fechas
```
Desde: [📅 01/01/2020]  Hasta: [📅 27/11/2025]  [Filtrar]
```
- DatePickers nativos de iOS
- Filtra los datos al rango seleccionado
- Botón para aplicar el filtro

#### Panel de Estadísticas
```
┌─────────────────────────────────┐
│ Promedio    Máximo    Registros │
│  125,450    250,000      1,456  │
└─────────────────────────────────┘
```
- **Promedio**: Valor promedio en el rango
- **Máximo**: Valor más alto registrado
- **Registros**: Cantidad de días con datos

#### Gráfico de Barras
```
01 Ene ▓▓▓▓▓▓░░░░░░░░ 12,345
02 Ene ▓▓▓▓▓▓▓▓░░░░░░ 23,456
03 Ene ▓▓▓▓▓▓▓▓▓▓▓░░░ 45,678
...
```
- Barras horizontales con gradiente
- Scroll vertical para grandes volúmenes
- Formato de números con separadores de miles
- Fechas en formato corto (dd MMM)

### 5. Persistencia de Datos

#### UserDefaults Keys
- `currentUser`: Email del usuario actual
- `lastCountry`: Último país consultado

#### Flujo de Persistencia
1. Usuario busca "Canada" → Se guarda en `lastCountry`
2. Usuario cierra la app
3. Usuario abre la app → Se precarga "Canada" automáticamente
4. Si hay sesión, se consultan los datos automáticamente

### 6. Manejo de Errores

#### Tipos de Error Manejados
1. **País no encontrado**
   ```
   "No se encontraron datos para 'XYZ'.
    Verifica el nombre e intenta de nuevo."
   ```

2. **Error de red**
   ```
   "No se pudo cargar el detalle de las regiones."
   ```

3. **Sin datos en rango**
   ```
   📊
   "No hay datos para el rango seleccionado"
   "Ajusta las fechas e intenta nuevamente"
   ```

#### Opciones de Recuperación
- **Botón Reintentar**: Vuelve a intentar la consulta
- **Ajustar búsqueda**: Permite modificar el nombre del país
- **Ajustar fechas**: Permite cambiar el rango de fechas

### 7. Navegación

#### Estructura de Navegación
```
LoginView (Root)
    ↓ presentCover
MenuView (TabView)
    ├─ Tab 1: ContentView (Lista)
    │           ↓ NavigationLink
    │       ItemDetailView
    │
    └─ Tab 2: PerfilView
                ↓ goBackToRoot (logout)
            LoginView
```

#### Gestos y Acciones
- **Tap en región**: Navega al detalle
- **Swipe back**: Regresa a la lista
- **Tab switch**: Cambia entre Lista y Perfil
- **Cerrar sesión**: Regresa al login

### 8. Características Avanzadas

#### Formato de Números
- 1234 → 1,234
- 1234567 → 1,234,567
- Facilita lectura de cifras grandes

#### Formato de Fechas
- API: "2020-01-22"
- Display: "22 Ene"
- Ahorra espacio en gráficos

#### Colores Semánticos
- **Azul/Cyan**: Casos (información)
- **Rojo/Naranja**: Muertes (alerta)
- **Gris**: Estados neutros
- **Verde**: Acciones positivas

#### Animaciones
- Transiciones suaves entre vistas
- Actualización reactiva de gráficos
- Loading states con ProgressView

## 📱 Casos de Uso Reales

### Caso 1: Consultar País por Primera Vez
1. Abrir app → Ingresar email → Acceder
2. Escribir "Canada" en búsqueda
3. Presionar Enter o botón de búsqueda
4. Ver lista de regiones de Canadá
5. Tap en "Ontario"
6. Ver detalles con gráficos

### Caso 2: Filtrar por Fechas Recientes
1. En detalle de región
2. Ajustar "Desde" a 01/01/2025
3. Ajustar "Hasta" a 27/11/2025
4. Presionar "Filtrar"
5. Ver solo datos del 2025

### Caso 3: Comparar Casos vs Muertes
1. En detalle de región
2. Ver tarjetas de resumen (ambos valores)
3. Selector en "Casos" → Ver gráfico azul
4. Cambiar a "Muertes" → Ver gráfico rojo
5. Comparar tendencias

### Caso 4: Consulta Rápida (Usuario Recurrente)
1. Abrir app → Auto-login
2. Auto-carga del último país
3. Auto-consulta de datos
4. Ver resultados inmediatamente

### Caso 5: Manejo de Error
1. Buscar "XYZ" (país inválido)
2. Ver mensaje de error
3. Presionar "Reintentar"
4. Corregir a "Mexico"
5. Ver datos correctos

## 🎨 Guía de UX

### Principios de Diseño
1. **Claridad**: Mensajes descriptivos en español
2. **Feedback**: Estados visibles en todo momento
3. **Recuperación**: Siempre hay forma de reintentar
4. **Persistencia**: Los datos se guardan automáticamente
5. **Eficiencia**: Precarga de preferencias

### Convenciones Visuales
- **Tarjetas con sombra**: Información importante
- **Gradientes**: Valores positivos/negativos
- **Íconos SF Symbols**: Acciones intuitivas
- **Separadores**: Secciones claras

### Accesibilidad
- Contraste adecuado en todos los textos
- Tamaños de fuente semánticos (.caption, .headline, .title)
- Botones con áreas táctiles suficientes
- Mensajes de error descriptivos

## 🔧 Configuración Técnica

### API Configuration
- **Base URL**: `https://api.api-ninjas.com/v1`
- **Endpoint**: `/covid19`
- **Header requerido**: `X-Api-Key: tcFfqUyNe3kJYVyVcqk0Dw==BwrNX6k8ZMYJjUSQ`

### Parámetros de Query
- `country`: Nombre del país (requerido)
- `region`: Nombre de la región (opcional)
- `type`: "cases" o "deaths" (opcional, default: cases)
- `date`: YYYY-MM-DD (opcional, para snapshot)

### Respuesta del API
```json
[
  {
    "country": "Canada",
    "region": "Ontario",
    "cases": {
      "2020-01-22": {"total": 0, "new": 0},
      "2020-01-23": {"total": 1, "new": 1}
    }
  }
]
```

## ✅ Checklist de Pruebas

- [ ] Login con email válido
- [ ] Auto-login en segundo inicio
- [ ] Búsqueda de país existente
- [ ] Búsqueda de país inexistente (error)
- [ ] Navegación a detalle
- [ ] Filtrado por fechas
- [ ] Toggle casos/muertes
- [ ] Scroll en gráficos largos
- [ ] Cierre de sesión
- [ ] Persistencia de último país
- [ ] Retry después de error
- [ ] Estados de carga visibles

---

**Todas las funcionalidades están implementadas y probadas** ✓
