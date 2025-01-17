require "zip"

DUMP_DIR = "dump"
MODS_DIR = "mods"

zip_files = Dir.glob("*.zip", base: MODS_DIR)
zip_files.each do |zip_file_name|
  mod_name = zip_file_name.split(".zip")[0..-1]

  if !Dir.exist?(File.join(DUMP_DIR, mod_name))
    Dir.mkdir(File.join(DUMP_DIR, mod_name))
  end

  Zip::File.open(File.join(MODS_DIR, zip_file_name)) do |zip_file|
    zip_file.each do |file|
      puts "About to extract #{file}"
      filepath = File.join(DUMP_DIR, mod_name, file.name)
      zip_file.extract(file, filepath) { true }
    end
  end

  if File.exist?(File.join(DUMP_DIR, mod_name, "info.json"))
    File.read(File.join(DUMP_DIR, mod_name, "info.json")) do |file|
      puts file
    end
  end
end
