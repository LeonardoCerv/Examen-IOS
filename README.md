# COVID-19 Tracker iOS App

Aplicación iOS desarrollada con SwiftUI siguiendo la arquitectura MVVM + Clean Architecture + FlowStacks para el seguimiento de datos de COVID-19 por país y región.

## 🏗️ Arquitectura

La aplicación sigue estrictamente el patrón **MVVM + Clean Architecture** con las siguientes capas:

### Framework (Presentación)
- **Views**: Interfaces de usuario en SwiftUI sin lógica de negocio
  - `LoginView.swift`: Pantalla de inicio de sesión
  - `MenuView.swift`: TabView principal (Listado y Perfil)
  - `ContentView.swift`: Lista de regiones COVID con búsqueda por país
  - `ItemDetailView.swift`: Detalle con gráficos y filtros de fecha
  - `PerfilView.swift`: Perfil de usuario con cierre de sesión
  - `CoordinatorView.swift`: Navegación con FlowStacks

- **ViewModels**: ObservableObjects que coordinan UI ↔ Domain
  - `LoginViewModel.swift`: Gestión de autenticación
  - `ItemListViewModel.swift`: Búsqueda de países y carga de regiones
  - `PerfilViewModel.swift`: Gestión de perfil de usuario

### Domain (Casos de Uso)
- **Requirements**: Implementan la lógica de negocio
  - `ItemListRequirement.swift`: Obtención de catálogo de regiones
  - `ItemDetailRequirement.swift`: Obtención de detalles de región
  - `UserRequirement.swift`: Gestión de usuario y preferencias

### Data (Repositorios y Servicios)
- **Repositories**
  - `ItemRepository.swift`: Gestiona peticiones al API de COVID
  - `UserRepository.swift`: Gestiona persistencia local de usuario

- **Network**
  - `NetworkAPIService.swift`: Servicio HTTP con Alamofire y headers de API

- **Local**
  - `LocalService.swift`: Persistencia con UserDefaults (email y último país)

- **Models**
  - `DomainModels.swift`: Modelos Codable para API y UI

## 📦 Dependencias

- **SwiftUI**: Framework de UI declarativo
- **Alamofire**: Cliente HTTP para peticiones a la API
- **SDWebImageSwiftUI**: Carga de imágenes remotas (preparado para extensión)
- **FlowStacks**: Gestión de navegación coordinada
- **async/await**: Concurrencia moderna con @MainActor

## 🚀 Características Principales

### 1. Autenticación
- Login con correo electrónico
- Persistencia de sesión con UserDefaults
- Auto-login si existe sesión previa
- Cierre de sesión desde el perfil

### 2. Búsqueda de Datos COVID
- Búsqueda de países por nombre (ej: Canada, Italy, Spain)
- Carga automática del último país consultado
- Estados de UI claros:
  - **Cargando**: ProgressView durante peticiones
  - **Éxito**: Lista de regiones con datos
  - **Error**: Mensaje descriptivo con botón de reintentar
- Lista de regiones por país con navegación

### 3. Visualización de Datos
- **Tarjetas Resumen**: Casos y muertes totales con fechas
- **Selector de Tipo**: Toggle entre Casos y Muertes
- **Filtrado por Fechas**: DatePickers para rango de fechas
- **Gráficos Mejorados**: 
  - Barras horizontales con gradientes
  - Estadísticas del rango (promedio, máximo, registros)
  - Formato de números con separadores de miles
  - Fechas en formato legible (dd MMM)
  - Scroll para grandes volúmenes de datos

### 4. Gestión de Preferencias
- Último país buscado guardado automáticamente
- Precarga de datos al abrir la app
- Email de usuario persistente

## 🔌 API Utilizada

**API Ninjas COVID-19 API**
- Endpoint: `https://api.api-ninjas.com/v1/covid19`
- Documentación: https://api-ninjas.com/api/covid19

### Parámetros Soportados
- `country`: Nombre del país (requerido)
- `region`: Región administrativa (opcional)
- `type`: "cases" o "deaths" (opcional)
- `date`: Fecha específica YYYY-MM-DD (opcional)

### Headers
- `X-Api-Key`: Clave de autenticación del API

## 📱 Flujo de Usuario

```
1. LoginView
   ├─ Si hay sesión → Auto-login → MenuView
   └─ Sin sesión → Ingreso de correo → MenuView

2. MenuView (TabView)
   ├─ Tab "Listado" → ContentView
   │  ├─ Búsqueda de país
   │  ├─ Lista de regiones
   │  └─ Tap región → ItemDetailView
   │     ├─ Resumen (Casos y Muertes)
   │     ├─ Selector Casos/Muertes
   │     ├─ Filtro de fechas
   │     └─ Gráficos interactivos
   │
   └─ Tab "Perfil" → PerfilView
      ├─ Muestra email
      └─ Botón cerrar sesión → LoginView
```

## 🎨 Detalles de Implementación

### Modelos de Datos
```swift
// Respuesta del API
struct CovidRegionResponse: Codable {
    let country: String
    let region: String
    let cases: [String: CaseData]?    // Fecha → Datos de casos
    let deaths: [String: CaseData]?   // Fecha → Datos de muertes
}

// Modelo de UI
struct ItemBase: Identifiable {
    var id: String              // Nombre de región
    var ref: ItemRef           // Referencia ligera
    var detail: ItemDetail?    // Detalle completo
}
```

### Navegación con FlowStacks
```swift
enum Screen {
    case menu
}

// Login → .presentCover(.menu)
// Logout → .goBackToRoot()
```

### Gestión de Estado
- `@Published` para propiedades reactivas
- `@MainActor` para mutaciones de UI
- `Task { await ... }` para llamadas asíncronas desde `onAppear`

## 🛠️ Compilación y Ejecución

1. Abrir `examen.xcodeproj` en Xcode
2. Seleccionar un simulador o dispositivo iOS
3. Build y Run (⌘+R)

**Requisitos:**
- Xcode 14.0+
- iOS 15.0+
- Swift 5.5+

## 📝 Estructura de Archivos

```
examen/
├── examenApp.swift                      # Entry point
├── Data/
│   ├── Modelos/
│   │   └── DomainModels.swift          # Modelos Codable
│   ├── Network/
│   │   └── NetworkAPIService.swift     # Servicio HTTP (Alamofire)
│   ├── Local/
│   │   └── LocalService.swift          # UserDefaults
│   ├── ItemRepository.swift            # Repo de COVID data
│   └── UserRepository.swift            # Repo de usuario
├── Domain/
│   ├── ItemListRequirement.swift       # Caso de uso: Lista
│   ├── ItemDetailRequirement.swift     # Caso de uso: Detalle
│   └── UserRequirement.swift           # Caso de uso: Usuario
└── Framework/
    ├── ViewModels/
    │   ├── ItemListViewModel.swift     # VM: Búsqueda y lista
    │   ├── LoginViewModel.swift        # VM: Login
    │   └── PerfilViewModel.swift       # VM: Perfil
    └── Views/
        ├── CoordinatorView.swift       # Navegación FlowStacks
        ├── LoginView.swift             # Pantalla login
        ├── MenuView.swift              # TabView principal
        ├── ContentView.swift           # Lista de regiones
        ├── ItemDetailView.swift        # Detalle con gráficos
        └── PerfilView.swift            # Perfil usuario
```

## ✅ Checklist de Requerimientos

- ✅ Consulta de datos por país con input libre
- ✅ Filtrado por fechas con DatePickers
- ✅ Presentación creativa de datos (gráficos, estadísticas)
- ✅ Estados de carga (loading, success, error)
- ✅ Mensajes de error descriptivos con retry
- ✅ Búsqueda de país por nombre
- ✅ Guardado de preferencia de último país
- ✅ Auto-carga de último país al iniciar
- ✅ Arquitectura MVVM + Clean + FlowStacks
- ✅ Alamofire para HTTP
- ✅ async/await con @MainActor
- ✅ UserDefaults para persistencia
- ✅ Textos en español

## 🎯 Funcionalidades Destacadas

1. **UX Mejorada**: Estados claros, mensajes descriptivos, retry automático
2. **Visualización Rica**: Gráficos con gradientes, estadísticas, formato de números
3. **Persistencia Inteligente**: Último país consultado para rápido acceso
4. **Filtrado Flexible**: Rangos de fechas personalizables
5. **Datos Duales**: Toggle entre casos y muertes
6. **Arquitectura Limpia**: Separación clara de responsabilidades
7. **Código Idiomático**: SwiftUI moderno, async/await, @MainActor

## 📖 Uso del API

```swift
// Ejemplo: Buscar datos de Canadá
GET https://api.api-ninjas.com/v1/covid19?country=canada
Headers: X-Api-Key: tcFfqUyNe3kJYVyVcqk0Dw==BwrNX6k8ZMYJjUSQ

// Ejemplo: Buscar muertes en región específica
GET https://api.api-ninjas.com/v1/covid19?country=canada&region=Alberta&type=deaths
```

## 🔐 Seguridad

- API Key hardcoded para propósitos del examen
- En producción: usar variables de entorno o Keychain
- Validación de inputs en ViewModels
- Manejo de errores en todos los niveles

## 🧪 Testing

Estructura preparada para tests:
- `examenTests/`: Unit tests
- `examenUITests/`: UI tests

---

**Desarrollado con ❤️ siguiendo Clean Architecture y mejores prácticas de SwiftUI**
