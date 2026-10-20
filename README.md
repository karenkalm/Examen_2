# StoreHub

App móvil multiplataforma hecha en **Flutter / Dart** para administrar un catálogo de productos consumiendo la [FakeStore API](https://fakestoreapi.com/products/). Incluye módulo de autenticación (login y registro), catálogo con búsqueda y filtros, detalles del producto y las operaciones de agregar, editar y eliminar.

> Segunda parcial · Programación de aplicaciones · Facultad de Ingeniería, Universidad de Colima
> Autor: **Jorge Luis Pizano Saucedo**

### 🌐 Ver la app en línea: **https://karenkalm.github.io/Examen_2/**

Usuario de prueba: `admin` · Contraseña: `admin123`. Las respuestas de la práctica están en [RESPUESTAS.md](RESPUESTAS.md).

![Flutter](https://img.shields.io/badge/Flutter-3.38-02569B?logo=flutter) ![Dart](https://img.shields.io/badge/Dart-3.10-0175C2?logo=dart) ![CI](https://github.com/karenkalm/Examen_2/actions/workflows/flutter-ci.yml/badge.svg)

---

## Funcionalidades

| Requisito | Dónde está |
|---|---|
| UI "Inicio de sesión" + registro | `lib/screens/auth/login_screen.dart`, `register_screen.dart` |
| Comparación de los datos con las variables al presionar **Ingresar** | `AuthService.login()` en `lib/services/auth_service.dart` |
| Usuario y contraseña no pueden ir vacíos | `Validators.requiredField()` en `lib/core/validators.dart` |
| UI "Productos" (cards con título, precio, descripción, categoría e imagen) | `lib/screens/products/products_screen.dart`, `lib/widgets/product_card.dart` |
| UI "Detalles" | `lib/screens/products/product_detail_screen.dart` |
| Agregar producto (POST) | `ProductFormScreen` + `ProductProvider.addProduct()` |
| Editar producto (PUT) | `ProductFormScreen` + `ProductProvider.updateProduct()` |
| Eliminar producto (DELETE) | Diálogo de confirmación + `ProductProvider.deleteProduct()` |
| Buscar / filtrar | Buscador, chips de categoría y orden (`ProductProvider.visibleProducts`) |
| Validaciones de formularios | `lib/core/validators.dart` |

Detalles extra: modo claro/oscuro automático, diseño responsivo (2 columnas en celular, más en tablet/escritorio), animaciones (Hero en la imagen, entrada escalonada de las cards, sacudida del formulario cuando el login falla), vibración al confirmar o fallar, vista previa en vivo al crear un producto y modo sin conexión.

## Módulo de autenticación (login / registro)

**Usuario de prueba** (definido en variables dentro de `AuthService`):

| Usuario | Contraseña |
|---|---|
| `admin` | `admin123` |

En la pantalla de login hay un aviso con estos datos; al tocarlo se llenan los campos.

Cómo funciona:

1. **Validación:** al presionar **Ingresar**, el `Form` revisa que usuario y contraseña no estén vacíos. Si falta alguno se muestra el error debajo del campo y el formulario se sacude.
2. **Comparación:** `AuthService.login()` compara lo escrito con las variables `demoUsername` y `demoPassword`. Si no coincide, busca entre los usuarios registrados. El usuario no distingue mayúsculas; la contraseña sí.
3. **Registro:** pide nombre, usuario, correo, contraseña y confirmación, todos validados (usuario de 4 a 20 caracteres sin espacios, correo válido, contraseña de mínimo 6 caracteres con letras y números, y que ambas contraseñas coincidan). No permite usuarios ni correos repetidos. La cuenta se guarda en el dispositivo con `shared_preferences` y la contraseña **cifrada con SHA-256**, nunca en texto plano.
4. **Sesión:** al entrar se guarda la sesión, así que la app abre directo en el catálogo la próxima vez. Desde el avatar o el menú se puede cerrar sesión.

Archivos: `lib/services/auth_service.dart`, `lib/providers/auth_provider.dart`, `lib/models/app_user.dart`, `lib/screens/auth/`, `lib/screens/auth_gate.dart`.

## Estructura de `lib/`

```
lib/
├── main.dart                # Punto de entrada, providers y tema
├── core/                    # Constantes, tema, validaciones, categorías y utilidades de UI
├── models/                  # Product, Rating y AppUser
├── services/                # ProductService (API), AuthService, almacenamiento local y errores
├── providers/               # AuthProvider y ProductProvider (estado con provider)
├── screens/
│   ├── auth_gate.dart       # Decide entre splash, login o productos
│   ├── auth/                # Login y registro
│   └── products/            # Catálogo, detalles y formulario
└── widgets/                 # Cards, imágenes, botones, estados vacíos/error y animaciones
```

## Cómo ejecutarla

```bash
flutter pub get
flutter run            # Android, iOS, Chrome o Windows
flutter test           # pruebas de validaciones, modelos, login y registro
```

Dependencias: `http`, `provider`, `shared_preferences` y `crypto`.

## Sobre la FakeStore API

La API responde correctamente a `POST`, `PUT` y `DELETE`, pero **no guarda los cambios** (si vuelves a pedir `/products` llegan los 20 originales). Por eso la app recuerda en el dispositivo lo que agregas, editas o eliminas y lo aplica encima del catálogo. Además, el `POST` siempre regresa `id: 21`, así que la app asigna un id único a cada producto nuevo. En el menú **⋮ › Restablecer catálogo** se borran esos cambios.

---

## Preguntas de comprensión

Las respuestas también están en [RESPUESTAS.md](RESPUESTAS.md), junto con los datos del módulo de autenticación.

### 1. ¿Proporciona el código generado para el Future?

`lib/services/product_service.dart`:

```dart
/// GET /products: obtiene el catálogo completo.
Future<List<Product>> fetchProducts() async {
  final response = await _send(
    () => _client.get(ApiConfig.products(), headers: _headers),
  );
  final data = _decode(response);
  if (data is! List) {
    throw const ApiException('El servidor envió una respuesta inesperada.');
  }
  return data
      .whereType<Map<String, dynamic>>()
      .map(Product.fromJson)
      .toList();
}
```

Ese `Future` se usa en `ProductProvider.loadProducts()`, y lo mismo se hace con `createProduct()` (POST), `updateProduct()` (PUT) y `deleteProduct()` (DELETE).

### 2. ¿Para qué sirve `async` y qué hace `await`?

`async` marca una función como asíncrona: siempre regresa un `Future` y permite usar `await` dentro de ella. `await` pausa esa función (sin congelar la interfaz) hasta que el `Future` termina, y entrega su resultado o lanza su error para atraparlo con `try/catch`. Por ejemplo, `await _client.get(...)` espera la respuesta de la API antes de convertir el JSON en productos.

### 3. ¿Nombre del modelo(s) creados para el proyecto?

- `Product`: id, title, price, description, category, image, rating (`lib/models/product.dart`).
- `Rating`: rate y count de cada producto (mismo archivo).
- `AppUser`: usuario del login/registro (`lib/models/app_user.dart`).

### 4. ¿Qué sucede si no hay conexión a Internet?

La petición falla con `ClientException` (o con `TimeoutException` después de 15 s). `ProductService` la convierte en un `ApiException` con el mensaje *"Sin conexión a internet"*. Entonces:

- Si ya se había descargado el catálogo antes, se muestra el último guardado en el dispositivo con un aviso **"Sin conexión"** y un botón **Reintentar**.
- Si nunca se descargó, aparece una pantalla con el ícono de wifi apagado y el botón **Reintentar**.
- Agregar, editar o eliminar muestra el error en un mensaje y no modifica nada.
- El login y el registro sí funcionan sin internet porque son locales.

### 5. ¿Lista las carpetas generadas dentro de la carpeta `lib`?

`core`, `models`, `services`, `providers`, `screens` (con las subcarpetas `auth` y `products`) y `widgets`, además del archivo `main.dart`.
