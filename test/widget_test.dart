import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storehub/core/validators.dart';
import 'package:storehub/models/product.dart';
import 'package:storehub/providers/auth_provider.dart';
import 'package:storehub/screens/auth/login_screen.dart';
import 'package:storehub/services/auth_service.dart';
import 'package:storehub/services/product_local_store.dart';

void main() {
  group('Validaciones', () {
    test('el login no acepta campos vacíos', () {
      expect(
        Validators.requiredField('', 'Ingresa tu usuario'),
        'Ingresa tu usuario',
      );
      expect(Validators.requiredField('   ', 'vacío'), 'vacío');
      expect(Validators.requiredField('admin', 'vacío'), isNull);
    });

    test('precio', () {
      expect(Validators.price(''), isNotNull);
      expect(Validators.price('abc'), isNotNull);
      expect(Validators.price('0'), isNotNull);
      expect(Validators.price('12.345'), isNotNull);
      expect(Validators.price('109.95'), isNull);
      expect(Validators.price('15'), isNull);
    });

    test('url de imagen', () {
      expect(Validators.imageUrl(''), isNotNull);
      expect(Validators.imageUrl('hola'), isNotNull);
      expect(Validators.imageUrl('ftp://sitio.com/a.png'), isNotNull);
      expect(Validators.imageUrl('https://fakestoreapi.com/img/1.jpg'), isNull);
    });

    test('registro', () {
      expect(Validators.email('correo@'), isNotNull);
      expect(Validators.email('jorge@ucol.mx'), isNull);
      expect(Validators.username('jo'), isNotNull);
      expect(Validators.username('jorge pizano'), isNotNull);
      expect(Validators.username('jorge_pizano'), isNull);
      expect(Validators.password('abcdef'), isNotNull);
      expect(Validators.password('abc123'), isNull);
      expect(Validators.confirmPassword('abc124', 'abc123'), isNotNull);
    });
  });

  group('Modelos', () {
    test('Product.fromJson convierte la respuesta de la API', () {
      final product = Product.fromJson({
        'id': 1,
        'title': 'Mochila',
        'price': 109.95,
        'description': 'Mochila para laptop',
        'category': "men's clothing",
        'image': 'https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg',
        'rating': {'rate': 3.9, 'count': 120},
      });
      expect(product.id, 1);
      expect(product.price, 109.95);
      expect(product.rating.count, 120);
      expect(product.formattedPrice, r'$109.95');
    });

    test('acepta precios enteros y respuestas sin rating (POST)', () {
      final product = Product.fromJson({
        'id': 21,
        'title': 'Nuevo',
        'price': 15,
        'description': 'Producto creado',
        'category': 'electronics',
        'image': 'https://example.com/a.png',
      });
      expect(product.price, 15.0);
      expect(product.hasRating, isFalse);
    });

    test('los cambios locales se aplican sobre la lista de la API', () {
      const a = Product(
        id: 1,
        title: 'A',
        price: 1,
        description: 'desc',
        category: 'electronics',
        image: '',
      );
      const b = Product(
        id: 2,
        title: 'B',
        price: 2,
        description: 'desc',
        category: 'jewelery',
        image: '',
      );
      final changes = LocalChanges(
        created: [a.copyWith(id: 21, title: 'Nuevo', isLocal: true)],
        edited: {1: a.copyWith(title: 'A editado')},
        deleted: {2},
      );
      final result = changes.applyTo([a, b]);
      expect(result.map((p) => p.title), ['Nuevo', 'A editado']);
    });
  });

  group('AuthService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('acepta el usuario de prueba (variables)', () async {
      final user = await AuthService().login(
        AuthService.demoUsername,
        AuthService.demoPassword,
      );
      expect(user.username, 'admin');
      expect(user.isDemo, isTrue);
    });

    test('rechaza credenciales incorrectas', () async {
      await expectLater(
        AuthService().login('admin', 'incorrecta'),
        throwsA(isA<AuthException>()),
      );
    });

    test('registra un usuario y luego inicia sesión', () async {
      final service = AuthService();
      await service.register(
        name: 'Jorge Pizano',
        username: 'jorge',
        email: 'jorge@ucol.mx',
        password: 'clave123',
      );
      final user = await service.login('Jorge', 'clave123');
      expect(user.name, 'Jorge Pizano');
      expect(user.passwordHash, isNot('clave123'));
    });

    test('no permite usuarios repetidos', () async {
      final service = AuthService();
      await service.register(
        name: 'Jorge Pizano',
        username: 'jorge',
        email: 'jorge@ucol.mx',
        password: 'clave123',
      );
      await expectLater(
        service.register(
          name: 'Otro',
          username: 'jorge',
          email: 'otro@ucol.mx',
          password: 'clave123',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  testWidgets('el login muestra errores si los campos están vacíos',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(AuthService()),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ingresar'));
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa tu usuario'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });
}
