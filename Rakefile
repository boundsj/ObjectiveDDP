PROJECT_NAME = "ObjectiveDDP"
APP_NAME = "ObjectiveDDP"
@configuration = "Debug"
@app_suffix = "-Dev"

SPECS_TARGET_NAME = "Specs"

SDK_VERSION = "6.1"
SDK_DIR = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator#{SDK_VERSION}.sdk"
BUILD_DIR = File.join(File.dirname(__FILE__), "build")

def build_dir(effective_platform_name)
  File.join(BUILD_DIR, @configuration + effective_platform_name)
end

def product_name
  "#{APP_NAME}#{@app_suffix}"
end

def grep_cmd_for_failure(cmd)
  retries = 0

  while retries < 10 do
    retries += 1

    puts "Executing #{cmd} and checking for FAILURE"
    result = %x[#{cmd} 2>&1]

    puts "Results:"
    puts result

    if result.include?("Simulator session timed out")
      puts "Simulator timed out, retrying..."
      kill_simulator
    else
      if !result.include?("Finished")
        exit(1)
      end

      if result.include?("FAILURE")
        exit(1)
      elsif result.include?("EXCEPTION")
        exit(1)
      else
        exit(0)
      end
    end
  end

  exit(1)
end

def system_or_exit(cmd, stdout = nil)
  puts "Executing #{cmd}"
  cmd += " >#{stdout}" if stdout
  system(cmd) or raise "******** Build failed ********"
end

def with_env_vars(env_vars)
  old_values = {}
  env_vars.each do |key,new_value|
    old_values[key] = ENV[key]
    ENV[key] = new_value
  end

  yield

  env_vars.each_key do |key|
    ENV[key] = old_values[key]
  end
end

def output_file(target)
  output_dir = if ENV['IS_CI_BOX']
    ENV['CC_BUILD_ARTIFACTS']
  else
    Dir.mkdir(BUILD_DIR) unless File.exists?(BUILD_DIR)
    BUILD_DIR
  end

  output_file = File.join(output_dir, "#{target}.output")
  puts "Output: #{output_file}"
  output_file
end

def kill_simulator
  system %Q[killall -m -KILL "gdb"]
  system %Q[killall -m -KILL "otest"]
  system %Q[killall -m -KILL "iPhone Simulator"]
end

#task :default => [:trim_whitespace, :specs]
task :default => [:trim_whitespace, :clean, :build_app, :build_specs]

desc "CI build"
task :cruise => [:clean, :clean_simulator, :build_app, :specs]

desc "Trim whitespace"
task :trim_whitespace do
  filenames = `git status --short | grep --invert-match ^D | cut -c 4-`.split("\n")
  filenames.map! do |filename|
    if filename.include?('->')
      filename = filename.slice(filename.index("->")..-1)
      filename.gsub!('-> ', '')
    end
    filename
  end
  puts filenames.inspect
  system_or_exit %Q[echo '#{filenames.join("\n")}'| grep -E '.*\.m?[cmhn]\"?$' | xargs sed -i '' -e 's/    /    /g;s/ *$//g;']
end

desc "Clean simulator directories"
task :clean_simulator do
  system('rm -Rf ~/Library/Application\ Support/iPhone\ Simulator/5.1/Applications/*')
end

desc "Clean all targets"
task :clean do
  #system_or_exit "xcodebuild -workspace ObjectiveDDP.xcworkspace -scheme ObjectiveDDP -configuration #{@configuration} clean SYMROOT=#{BUILD_DIR}", output_file("clean")
  system_or_exit "xcodebuild -workspace ObjectiveDDP.xcworkspace -scheme ObjectiveDDP -configuration #{@configuration} clean", output_file("clean")
  FileUtils.rm_rf BUILD_DIR
end

desc "Build application"
task :build_app do
  system_or_exit(%Q[xcodebuild -configuration Debug -workspace ObjectiveDDP.xcworkspace -scheme ObjectiveDDP -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO ARCHS=i386 build], output_file("app"))
end

desc "Build specs"
task :build_specs do
  puts "SYMROOT: #{ENV['SYMROOT']}"
  system_or_exit(%Q[xcodebuild -configuration Debug -workspace ObjectiveDDP.xcworkspace -scheme Specs -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO ARCHS=i386 build], output_file("specs"))
end

desc "Build all targets"
task :build_all do
  kill_simulator
  system_or_exit "xcodebuild -alltargets build TEST_AFTER_BUILD=NO SYMROOT=#{BUILD_DIR}", output_file("build_all")
end

desc "Run specs"
task :specs => :build_specs do
  build_dir = build_dir("")
  with_env_vars("DYLD_FRAMEWORK_PATH" => build_dir) do
    system_or_exit("cd #{build_dir}; ./#{SPECS_TARGET_NAME}")
  end
end

desc "adds a release tag to git"
task :tag_git do
  release_tag = "#{@configuration.downcase}-#{agv_version}"
  system_or_exit("git tag #{release_tag}")
end

desc "ensures that there's nothing in the git index before creating a release"
task :require_clean_index do
  diff = `git diff-index --cached HEAD`
  if diff.length > 0
    raise "\nYou have uncommitted changes in your git index. You can't deploy with uncommitted changes."
  end
end

task :current_version do
  puts agv_version
end

def agv_version
  output = `agvtool what-version`.split("\n")[1]
  output.match(/(\d+)/)[1]
end
