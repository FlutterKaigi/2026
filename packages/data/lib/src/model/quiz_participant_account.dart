import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';

part 'quiz_participant_account.freezed.dart';
part 'quiz_participant_account.g.dart';

/// クイズの参加記録とログインアカウントの紐づけ。
///
/// ドキュメント ID は Firebase Auth の uid。ニックネームだけを持つ
/// `QuizParticipant` と違い、メールアドレスなど本人と運営にしか見せない情報を
/// 含むため、セキュリティルールで本人と運営のみ読めるようにしている。
@freezed
abstract class QuizParticipantAccount with _$QuizParticipantAccount {
  const QuizParticipantAccount._();

  const factory QuizParticipantAccount({
    required String uid,
    required String signInProvider,
    @FirestoreDateTimeConverter() required DateTime linkedAt,
    String? email,
    String? accountName,
    String? photoUrl,
  }) = _QuizParticipantAccount;

  factory QuizParticipantAccount.fromJson(Map<String, dynamic> json) => _$QuizParticipantAccountFromJson(json);
}
