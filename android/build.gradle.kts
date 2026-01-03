// 🔐 REQUIRED for Firebase Google Services
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ✅ Firebase Google Services classpath (ADDED)
        classpath("com.google.gms:google-services:4.4.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// =============================
// 🔧 FLUTTER BUILD DIRECTORY FIX (RETAINED)
// =============================
val newBuildDir: Directory =
    rootProject.layout.buildDirectory.dir("../../build").get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// =============================
// 🧹 CLEAN TASK (RETAINED)
// =============================
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
