import 'dart:ui';

import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:thingsboard_app/config/routes/router.dart';
import 'package:thingsboard_app/constants/assets_path.dart';
import 'package:thingsboard_app/core/auth/login/bloc/bloc.dart';
import 'package:thingsboard_app/core/auth/login/di/login_di.dart';
import 'package:thingsboard_app/core/auth/login/select_region/choose_region_screen.dart';
import 'package:thingsboard_app/core/auth/login/select_region/model/region.dart';
import 'package:thingsboard_app/core/auth/oauth2/i_oauth2_client.dart';
import 'package:thingsboard_app/core/context/tb_context_widget.dart';
import 'package:thingsboard_app/generated/l10n.dart';
import 'package:thingsboard_app/locator.dart';
import 'package:thingsboard_app/thingsboard_client.dart';
import 'package:thingsboard_app/utils/services/device_info/i_device_info_service.dart';
import 'package:thingsboard_app/utils/services/endpoint/i_endpoint_service.dart';
import 'package:thingsboard_app/utils/services/overlay_service/i_overlay_service.dart';
import 'package:thingsboard_app/utils/ui/tb_text_styles.dart';
import 'package:thingsboard_app/widgets/tb_progress_indicator.dart';

// A modern, tech-inspired background widget with the new color scheme
class _ModernLoginPageBackground extends StatelessWidget {
  const _ModernLoginPageBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF040F24), // A deeper, richer navy blue
            Color(0xFF1d4580), // The user's primary color
          ],
        ),
      ),
    );
  }
}

class LoginPage extends TbPageWidget {
  LoginPage(super.tbContext, {super.key});

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends TbPageState<LoginPage>
    with WidgetsBindingObserver {
  final _isLoginNotifier = ValueNotifier<bool>(false);
  final _showPasswordNotifier = ValueNotifier<bool>(false);
  final IDeviceInfoService _deviceInfoService = getIt<IDeviceInfoService>();
  final IOverlayService _overlayService = getIt<IOverlayService>();
  final _loginFormKey = GlobalKey<FormBuilderState>();

  Region? selectedRegion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LoginDi.init();
    if (tbClient.isPreVerificationToken()) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        getIt<ThingsboardAppRouter>().navigateTo('/login/mfa');
      });
    }
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final region = await getIt<IEndpointService>().getSelectedRegion();
      if (region != null && region != Region.custom) {
        setState(() {
          selectedRegion = region;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    LoginDi.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFF1d4580);
    final hintTextColor = Colors.white.withOpacity(0.7);

    final inputDecoration = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      hintStyle: TextStyle(color: hintTextColor),
      labelStyle: TextStyle(color: hintTextColor),
      errorStyle: const TextStyle(color: Color(0xFFF48A8A)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF48A8A), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF48A8A), width: 2),
      ),
      prefixIconColor: hintTextColor,
      suffixIconColor: hintTextColor,
    );

    return BlocProvider<AuthBloc>(
      create:
          (_) =>
              AuthBloc(tbClient: tbClient, deviceService: _deviceInfoService)
                ..add(
                  AuthFetchEvent(
                    packageName: _deviceInfoService.getApplicationId(),
                    platformType: _deviceInfoService.getPlatformType(),
                  ),
                ),
      child: Scaffold(
        body: Stack(
          children: [
            const _ModernLoginPageBackground(),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                switch (state) {
                  case AuthLoadingState():
                    return const Center(child: TbProgressIndicator(size: 50.0));
                  case AuthDataState():
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: accentColor.withOpacity(0.4),
                                ),
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 400,
                                ),
                                child: _buildLoginForm(
                                  context,
                                  state,
                                  inputDecoration,
                                  accentColor,
                                  hintTextColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                }
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isLoginNotifier,
              builder: (BuildContext context, bool loading, child) {
                if (loading) {
                  return Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: TbProgressIndicator(size: 50.0)),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(
    BuildContext context,
    AuthDataState state,
    InputDecoration inputDecoration,
    Color accentColor,
    Color hintTextColor,
  ) {
    const buttonColor1 = Color(0xFF42A5F5); // Brighter blue
    const buttonColor2 = Color(0xFF1976D2); // Deeper blue

    return AutofillGroup(
      child: FormBuilder(
        key: _loginFormKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SvgPicture.asset(
              ThingsboardImage.thingsBoardWithTitle,
              height: 30,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
              semanticsLabel: S.of(context).logoDefaultValue,
            ),
            const SizedBox(height: 24),
            Text(
              S.of(context).loginNotification,
              textAlign: TextAlign.center,
              style: TbTextStyles.titleLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 32),
            if (state.oAuthClients.isNotEmpty)
              _buildOAuth2Buttons(state.oAuthClients),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.white.withOpacity(0.2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      state.oAuthClients.isNotEmpty
                          ? S.of(context).or
                          : S.of(context).loginWith,
                      style: TbTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.white.withOpacity(0.2)),
                  ),
                ],
              ),
            ),

            if (state.oAuthClients.isEmpty)
              Center(
                child: Tooltip(
                  message: S.of(context).scanQrCode,
                  child: OutlinedButton(
                    onPressed: () async => await _onLoginWithBarcode(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: const CircleBorder(),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: SvgPicture.asset(
                      // translate-me-ignore-next-line
                      ThingsboardImage.oauth2Logos['qr-code-logo']!,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        Colors.white.withOpacity(0.8),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),

            if (state.oAuthClients.isEmpty) const SizedBox(height: 16),

            FormBuilderTextField(
              autofillHints: const [AutofillHints.email],
              name: 'username',
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(
                  errorText: S.of(context).emailRequireText,
                ),
                FormBuilderValidators.email(
                  errorText: S.of(context).emailInvalidText,
                ),
              ]),
              decoration: inputDecoration.copyWith(
                prefixIcon: const Icon(Icons.email_outlined),
                labelText: S.of(context).email,
              ),
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder(
              valueListenable: _showPasswordNotifier,
              builder: (BuildContext context, bool showPassword, child) {
                return FormBuilderTextField(
                  autofillHints: const [AutofillHints.password],
                  name: 'password',
                  style: const TextStyle(color: Colors.white),
                  obscureText: !showPassword,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: S.of(context).passwordRequireText,
                    ),
                  ]),
                  decoration: inputDecoration.copyWith(
                    prefixIcon: const Icon(Icons.lock_outline),
                    labelText: S.of(context).password,
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        _showPasswordNotifier.value =
                            !_showPasswordNotifier.value;
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                child: Text(
                  S.of(context).passwordForgotText,
                  style: TbTextStyles.bodyMedium.copyWith(color: hintTextColor),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [buttonColor1, buttonColor2],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: buttonColor1.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _login,
                child: Text(
                  S.of(context).login.toUpperCase(),
                  style: TbTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            _buildRegionSelector(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionSelector(BuildContext context) {
    if (selectedRegion == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Center(
        child: TextButton(
          onPressed: () {
            tbContext.showFullScreenDialog(
              ChooseRegionScreen(
                tbContext,
                nASelected: selectedRegion == Region.northAmerica,
                europeSelected: selectedRegion == Region.europe,
              ),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withOpacity(0.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedRegion?.regionToString(context) ?? '',
                style: TbTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onLoginWithBarcode(BuildContext context) async {
    FocusScope.of(context).unfocus();
    try {
      final Barcode? barcode = await getIt<ThingsboardAppRouter>().navigateTo(
        '/qrCodeScan',
        transition: TransitionType.nativeModal,
      );

      if (barcode != null && barcode.rawValue != null) {
        getIt<ThingsboardAppRouter>().navigateByAppLink(barcode.rawValue);
      }
    } catch (e) {
      log.error('Login with qr code error', e);
    }
  }

  Widget _buildOAuth2Buttons(List<OAuth2ClientInfo> clients) {
    final buttons =
        clients.map((client) => _buildOAuth2Button(client)).toList();

    // Add QR code button to the list
    buttons.add(
      Tooltip(
        message: S.of(context).scanQrCode,
        child: OutlinedButton(
          onPressed: () async => await _onLoginWithBarcode(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            shape: const CircleBorder(),
            side: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          child: SvgPicture.asset(
            // translate-me-ignore-next-line
            ThingsboardImage.oauth2Logos['qr-code-logo']!,
            height: 24,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.8),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: buttons,
    );
  }

  Widget _buildOAuth2Button(OAuth2ClientInfo client) {
    Widget? icon;
    if (client.icon != null) {
      if (ThingsboardImage.oauth2Logos.containsKey(client.icon)) {
        icon = SvgPicture.asset(
          ThingsboardImage.oauth2Logos[client.icon]!,
          height: 24,
          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(0.8),
            BlendMode.srcIn,
          ),
        );
      } else {
        String strIcon = client.icon!;
        if (strIcon.startsWith('mdi:')) {
          strIcon = strIcon.substring(4);
        }
        final iconData = MdiIcons.fromString(strIcon);
        if (iconData != null) {
          icon = Icon(iconData, size: 24, color: Colors.white.withOpacity(0.8));
        }
      }
    }
    icon ??= Icon(Icons.login, size: 24, color: Colors.white.withOpacity(0.8));

    return Tooltip(
      message: client.name,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: const CircleBorder(),
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        onPressed: () => _oauth2ButtonPressed(client),
        child: icon,
      ),
    );
  }

  Future<void> _oauth2ButtonPressed(OAuth2ClientInfo client) async {
    FocusScope.of(context).unfocus();
    _isLoginNotifier.value = true;
    try {
      final result = await getIt<IOAuth2Client>().authenticate(client.url);
      if (result.success) {
        await tbClient.setUserFromJwtToken(
          result.accessToken,
          result.refreshToken,
          true,
        );
      } else {
        _isLoginNotifier.value = false;
        _overlayService.showErrorNotification((_) => result.error!);
      }
    } catch (e) {
      log.error('Auth Error:', e);
      _isLoginNotifier.value = false;
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (_loginFormKey.currentState?.saveAndValidate() ?? false) {
      final formValue = _loginFormKey.currentState!.value;
      final String username = formValue['username'].toString();
      final String password = formValue['password'].toString();
      _isLoginNotifier.value = true;
      try {
        await tbClient.login(LoginRequest(username, password));
      } catch (e) {
        _isLoginNotifier.value = false;
        if (e is! ThingsboardError ||
            e.errorCode == ThingsBoardErrorCode.general) {
          await tbContext.onFatalError(e);
        }
      }
    }
  }

  Future<void> _forgotPassword() async {
    getIt<ThingsboardAppRouter>().navigateTo('/login/resetPasswordRequest');
  }
}
