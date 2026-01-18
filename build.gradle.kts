
plugins {
    kotlin("multiplatform") version "1.9.22"
    kotlin("plugin.serialization") version "1.9.22"
}

group = "xim"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

fun kotlinw(target: String): String =
    "org.jetbrains.kotlin-wrappers:kotlin-$target"

val kotlinWrappersVersion = "1.0.0-pre.710"

dependencies {
    commonMainImplementation(platform(kotlinw("wrappers-bom:$kotlinWrappersVersion")))
    commonMainImplementation(kotlinw("browser"))
    commonMainImplementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2")
}

data class NoOverlay(
    val errors: Boolean = false,
    val warnings: Boolean = false,
    val runtimeErrors: Boolean = false
)

kotlin {
    js {
        browser {
            commonWebpackConfig(Action {
                devServer?.port = 443
                devServer?.client?.overlay = NoOverlay()
            })
        }
        binaries.executable()
    }
}