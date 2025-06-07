import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Use a custom build directory to avoid nesting issues
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

// Update each subproject's build directory
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

// Ensure project dependencies are evaluated in the correct order
subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task to clear custom build directory
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
