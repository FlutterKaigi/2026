import 'package:data/data.dart';

/// Outcome of creating an exchange after a QR code has already been parsed
/// and confirmed not to be the scanning user's own.
sealed class CreateExchangeOutcome {
  const CreateExchangeOutcome();
}

/// The other attendee is already in the signed-in user's exchange list.
final class ExchangeAlreadyExists extends CreateExchangeOutcome {
  const ExchangeAlreadyExists();
}

/// Creating the exchange failed for a reason other than duplication.
final class ExchangeCreateFailed extends CreateExchangeOutcome {
  const ExchangeCreateFailed(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

/// The exchange was created in the signed-in user's list.
final class ExchangeCreated extends CreateExchangeOutcome {
  const ExchangeCreated();
}

/// Creates `users/{myUid}/exchanges/{otherUid}`, classifying the failure
/// modes the UI needs to distinguish.
///
/// Kept independent of `BuildContext` and the camera widget so it is
/// unit-testable without `mobile_scanner`.
final class ExchangeScanHandler {
  const ExchangeScanHandler({required this.myUid, required this.repository});

  final String myUid;
  final ProfileExchangeRepository repository;

  Future<CreateExchangeOutcome> createExchange({required String otherUid, required String token}) async {
    try {
      await repository.create(uid: myUid, otherUid: otherUid, token: token);
      return const ExchangeCreated();
    } on ProfileExchangeAlreadyExistsException {
      return const ExchangeAlreadyExists();
    } on Exception catch (error, stackTrace) {
      return ExchangeCreateFailed(error, stackTrace);
    }
  }
}
