require 'xcodeproj'
project = Xcodeproj::Project.open("./DSDemo.xcodeproj")
target = project.native_targets
.select { |target| target.name == 'DSDemo' }
.first

target.frameworks_build_phase.files.each do |f|
    if f.file_ref.path == "libPods-DSDemo.a"
    then
        puts f.file_ref.path
        f.remove_from_project
	break
    end
end
project.save
