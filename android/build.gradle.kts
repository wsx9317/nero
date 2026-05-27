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
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withId("com.android.library") {
        val androidExtension = extensions.findByName("android") ?: return@withId
        val getNamespace = androidExtension.javaClass.methods.find { method ->
            method.name == "getNamespace" && method.parameterCount == 0
        } ?: return@withId
        val setNamespace = androidExtension.javaClass.methods.find { method ->
            method.name == "setNamespace" && method.parameterCount == 1
        } ?: return@withId

        val currentNamespace = getNamespace.invoke(androidExtension) as? String
        if (!currentNamespace.isNullOrBlank()) {
            return@withId
        }

        val manifestFile = project.file("src/main/AndroidManifest.xml")
        if (!manifestFile.exists()) {
            return@withId
        }

        // Backfill namespace for older Android plugins that still use manifest package.
        val manifestPackage = Regex("package=\"([^\"]+)\"")
            .find(manifestFile.readText())
            ?.groupValues
            ?.getOrNull(1)

        if (!manifestPackage.isNullOrBlank()) {
            setNamespace.invoke(androidExtension, manifestPackage)
        }
    }

}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
