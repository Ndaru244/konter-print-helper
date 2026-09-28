import com.android.build.gradle.BaseExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// blue_thermal_printer pins compileSdk 31 and may omit namespace.
// Its AndroidX dependencies require compileSdk 34+.
subprojects {
    afterEvaluate {
        if (name != "blue_thermal_printer") return@afterEvaluate
        val android = extensions.findByName("android") as? BaseExtension ?: return@afterEvaluate
        if (android.namespace == null) {
            android.namespace = "id.kakzaki.blue_thermal_printer"
        }
        android.setCompileSdkVersion(36)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
