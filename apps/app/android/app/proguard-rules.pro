# JNI looks up these Kotlin runtime classes and members by name when calling
# SharedPreferences suspend methods. Keep them until package:jni ships the rules.
# https://github.com/dart-lang/native/issues/3732
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt { *; }
