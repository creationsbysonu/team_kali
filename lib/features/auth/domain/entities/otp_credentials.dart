import 'package:equatable/equatable.dart';

/// Entity for OTP request parameters.
class OtpRequest extends Equatable {
  final String email;

  const OtpRequest({required this.email});

  @override
  List<Object?> get props => [email];

  bool get isValidEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
}

/// Entity for OTP verification parameters.
class OtpVerification extends Equatable {
  final String email;
  final String otp;

  const OtpVerification({required this.email, required this.otp});

  @override
  List<Object?> get props => [email, otp];

  bool get isValidOtp => otp.length == 6 && int.tryParse(otp) != null;
}
