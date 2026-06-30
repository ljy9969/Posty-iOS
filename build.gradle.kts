plugins {
    id("com.android.application") version "9.2.1" apply false
    id("com.android.kotlin.multiplatform.library") version "9.2.1" apply false
    // Compose Multiplatform 1.11.1 의 iOS klib 은 Kotlin 2.3.20 컴파일러로 빌드됨(ABI 2.3.0).
    // Kotlin/Native 는 ABI 가 엄격하므로 컴파일러를 2.3.20 으로 맞춰야 iOS 링크가 된다.
    id("org.jetbrains.kotlin.multiplatform") version "2.3.20" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.3.20" apply false
    id("org.jetbrains.kotlin.plugin.serialization") version "2.3.20" apply false
    id("org.jetbrains.compose") version "1.11.1" apply false
}
