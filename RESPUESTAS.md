# Respuestas · Segunda parcial

**Alumno:** Jorge Luis Pizano Saucedo
**Materia:** Programación de aplicaciones
**Proyecto:** StoreHub (Flutter / Dart), catálogo de productos con la FakeStore API (https://fakestoreapi.com/products/)

---

## Datos del módulo de autenticación (login / registro)

| Usuario de prueba | Contraseña |
|---|---|
| `admin` | `admin123` |

- Los datos del usuario de prueba están en variables dentro de `lib/services/auth_service.dart` (`demoUsername` y `demoPassword`).
- Al presionar **Ingresar**, primero se valida que las cajas de texto *Usuario* y *Contraseña* no estén vacías (`Validators.requiredField`). Después, `AuthService.login()` compara lo que se escribió con esas variables. Si no coinciden, busca entre los usuarios registrados.
- En **Regístrate** se pide nombre, usuario, correo, contraseña y confirmación, todos validados. La cuenta se guarda en el dispositivo (`shared_preferences`) con la contraseña cifrada con SHA-256, y después se puede entrar con ella.
- La sesión queda guardada hasta presionar **Cerrar sesión**.

---

## Preguntas de comprensión del código del proyecto

### 1. ¿Proporciona el código generado para el Future?

Archivo `lib/services/product_service.dart`:

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

`ProductProvider.loadProducts()` usa este `Future` para llenar el catálogo. Los demás `Future` del servicio funcionan igual: `createProduct()` (POST), `updateProduct()` (PUT) y `deleteProduct()` (DELETE).

### 2. ¿Para qué sirve async y qué hace await?

`async` marca una función como asíncrona. La función siempre regresa un `Future` y dentro de ella se puede usar `await`. `await` pausa esa función hasta que el `Future` termina, sin congelar la interfaz. Luego entrega el resultado, o lanza el error para atraparlo con `try/catch`. Por ejemplo, `await _client.get(...)` espera la respuesta de la API antes de convertir el JSON en productos.

### 3. ¿Nombre del modelo(s) creados para el proyecto?

- `Product`: id, title, price, description, category, image y rating (`lib/models/product.dart`).
- `Rating`: rate y count de cada producto (mismo archivo).
- `AppUser`: el usuario del login y registro (`lib/models/app_user.dart`).

### 4. ¿Qué sucede si no hay conexión a Internet?

La petición falla con `ClientException`, o con `TimeoutException` después de 15 segundos. `ProductService` convierte ese error en un `ApiException` con el mensaje *"Sin conexión a internet"*. Después pasa esto:

- Si el catálogo ya se había descargado antes, la app muestra la copia guardada en el dispositivo con un aviso de **"Sin conexión"** y un botón **Reintentar**.
- Si nunca se descargó, aparece una pantalla con el ícono de wifi apagado y el botón **Reintentar**.
- Si se intenta agregar, editar o eliminar un producto, sale un mensaje de error y no se cambia nada.
- El login y el registro funcionan sin internet porque se guardan en el dispositivo.

### 5. ¿Lista las carpetas generadas dentro de la carpeta lib?

```
lib/
├── core/          # constantes, tema, validaciones, categorías y utilidades de UI
├── models/        # Product, Rating y AppUser
├── providers/     # AuthProvider y ProductProvider
├── screens/
│   ├── auth/      # login y registro
│   └── products/  # catálogo, detalles y formulario
├── services/      # ProductService (API), AuthService y almacenamiento local
├── widgets/       # cards, botones, estados vacíos/error y animaciones
└── main.dart
```

Carpetas: `core`, `models`, `providers`, `screens` (con `auth` y `products`), `services` y `widgets`.
