import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    // Verificar el dominio de correo electrónico
    if (!_isEmailDomainAllowed(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Este dominio de correo electrónico no está autorizado para registrarse.')),
      );
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response.user != null) {
        await Supabase.instance.client.from('users').insert({
          'id': response.user!.id,
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Registro exitoso. Por favor, inicia sesión.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (e is AuthException && e.message.contains('not authorized')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Este correo electrónico no está autorizado para registrarse. Por favor, utiliza un correo electrónico diferente.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de registro: $e')),
        );
      }
    }
  }

  bool _isEmailDomainAllowed(String email) {
    // Lista de dominios permitidos
    final allowedDomains = [
      'gmail.com',
      'hotmail.com',
      'desarrolloglobal.com.co'
    ]; // Ajusta esta lista según tus necesidades
    final domain = email.split('@').last;
    return allowedDomains.contains(domain);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return _buildWideLayout();
          } else {
            return _buildNarrowLayout();
          }
        },
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          child: _buildRegisterForm(),
        ),
        Expanded(
          child: Image.asset(
            'assets/images/bufalas.jpg',
            fit: BoxFit.cover,
            height: double.infinity,
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: _buildRegisterForm(),
    );
  }

  Widget _buildRegisterForm() {
    return Container(
      padding: EdgeInsets.all(32.0),
      color: Color(0xFFB5D99C),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Aplicación de Aforos',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Text(
            'Crear una cuenta',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Ingresa los siguientes datos:',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 24),
          _buildTextField(_nameController, 'Nombre'),
          SizedBox(height: 16),
          _buildTextField(_emailController, 'Email'),
          SizedBox(height: 16),
          _buildTextField(_phoneController, 'Teléfono'),
          SizedBox(height: 16),
          _buildPasswordField(
              _passwordController, 'Contraseña', _obscurePassword),
          SizedBox(height: 16),
          _buildPasswordField(_confirmPasswordController,
              'Confirmar Contraseña', _obscureConfirmPassword),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _signUp,
            child: Text(
              'Crear cuenta',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold, // Letra más gruesa
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(8.0), // Bordes menos redondeados
              ),
              elevation: 5, // Efecto de sombra
            ),
          ),
          SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              '¿Ya tienes una cuenta? Clic aquí',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0), // Bordes más redondeados
        ),
      ),
    );
  }

  Widget _buildPasswordField(
      TextEditingController controller, String label, bool obscureText) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0), // Bordes más redondeados
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              if (label == 'Contraseña') {
                _obscurePassword = !_obscurePassword;
              } else {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              }
            });
          },
        ),
      ),
    );
  }
}
