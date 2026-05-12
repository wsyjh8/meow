/// 需求 23 Phase B — Unified auth form page.
///
/// Single page handles three modes:
///   - register: new account (email + password + optional nickname)
///   - login:    existing account (email + password)
///   - bind:     upgrade current guest → registered (email + password)
///
/// Bind preserves users.id (plan v2 §6.2 same-row upgrade) so local
/// drift / SP data continues to belong to the user. AuthController
/// commits the new token + user info on success.
library;

import 'package:flutter/material.dart';

import '../../core/auth/auth.dart';
import '../../spec/theme/tokens.dart';

enum AuthFormMode { login, register, bind }

class AuthFormPage extends StatefulWidget {
  final AuthFormMode initialMode;
  const AuthFormPage({super.key, this.initialMode = AuthFormMode.login});

  @override
  State<AuthFormPage> createState() => _AuthFormPageState();
}

class _AuthFormPageState extends State<AuthFormPage> {
  late AuthFormMode _mode;
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _nicknameCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    _nicknameCtl.dispose();
    super.dispose();
  }

  String _title() {
    switch (_mode) {
      case AuthFormMode.login:
        return '登录';
      case AuthFormMode.register:
        return '注册账号';
      case AuthFormMode.bind:
        return '绑定账号';
    }
  }

  String _submitLabel() {
    switch (_mode) {
      case AuthFormMode.login:
        return '登录';
      case AuthFormMode.register:
        return '创建账号';
      case AuthFormMode.bind:
        return '绑定';
    }
  }

  String _footerPrompt() {
    switch (_mode) {
      case AuthFormMode.login:
        return '没有账号？去注册';
      case AuthFormMode.register:
        return '已有账号？去登录';
      case AuthFormMode.bind:
        return ''; // bind has no switch — user is upgrading current guest
    }
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == AuthFormMode.login
          ? AuthFormMode.register
          : AuthFormMode.login;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final controller = AuthScope.read(context);
    final email = _emailCtl.text.trim();
    final password = _passwordCtl.text;
    final nickname = _nicknameCtl.text.trim();

    try {
      switch (_mode) {
        case AuthFormMode.login:
          await controller.login(email: email, password: password);
          break;
        case AuthFormMode.register:
          await controller.register(
            email: email,
            password: password,
            nickname: nickname.isEmpty ? null : nickname,
          );
          break;
        case AuthFormMode.bind:
          await controller.bindCurrentGuest(
            email: email,
            password: password,
          );
          break;
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AuthApiException catch (e) {
      setState(() {
        _errorMessage = _humanize(e);
        _submitting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '网络异常，请稍后重试';
        _submitting = false;
      });
    }
  }

  /// Map server error_code → user-facing string. Keep them gentle (项目硬纪律 §3.4
  /// "温柔体验"). Never use blaming tone.
  String _humanize(AuthApiException e) {
    switch (e.errorCode) {
      case 'EMAIL_TAKEN':
        return '这个邮箱已经注册过了，可以直接登录';
      case 'INVALID_CREDENTIALS':
        return '邮箱或密码不对';
      case 'NOT_GUEST':
        return '当前账号已经是正式账号了';
      case 'GUEST_NOT_FOUND':
        return '当前游客账号不存在，请重启 App';
      default:
        return e.message.isNotEmpty ? e.message : '操作失败 (${e.statusCode})';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpecBg.canvas,
      appBar: AppBar(
        backgroundColor: SpecBg.canvas,
        elevation: 0,
        iconTheme: const IconThemeData(color: SpecText.primary),
        title: Text(
          _title(),
          style: const TextStyle(
            color: SpecText.primary,
            fontSize: 16,
            fontWeight: SpecTypo.medium,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SpecSpacing.pageH,
            8,
            SpecSpacing.pageH,
            16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_mode == AuthFormMode.bind)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: SpecBg.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '绑定后，你目前的学习进度、奖励和猫猫数据都会保留在新账号下。',
                      style: TextStyle(
                        fontSize: 13,
                        color: SpecText.secondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                TextFormField(
                  controller: _emailCtl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: '邮箱',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return '请输入邮箱';
                    if (!s.contains('@') || !s.contains('.')) {
                      return '邮箱格式不太对';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '密码（8-64 位）',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final s = v ?? '';
                    if (s.isEmpty) return '请输入密码';
                    if (_mode != AuthFormMode.login) {
                      if (s.length < 8) return '密码至少 8 位';
                      if (s.length > 64) return '密码不能超过 64 位';
                    }
                    return null;
                  },
                ),
                if (_mode == AuthFormMode.register) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nicknameCtl,
                    decoration: const InputDecoration(
                      labelText: '昵称（可选）',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE5E5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFB04444),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SpecBrand.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _submitting ? '请稍候…' : _submitLabel(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: SpecTypo.medium,
                    ),
                  ),
                ),
                if (_mode != AuthFormMode.bind) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: GestureDetector(
                      onTap: _submitting ? null : _toggleMode,
                      child: Text(
                        _footerPrompt(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: SpecText.purple,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
