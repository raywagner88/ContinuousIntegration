require 'sinatra'
require 'json'
require 'octokit'
require 'dotenv/load'
require 'shell/executer.rb'

ACCESS_TOKEN = ENV['ACCESS_TOKEN'] # GitHub OAuth Token / load via .env file

before do
    @client ||= Octokit::Client.new(:access_token => ACCESS_TOKEN)
end

post '/event_handler' do
@payload = JSON.parse(params[:payload])
@branch = @payload["pull_request"]["head"]["ref"]

case request.env['HTTP_X_GITHUB_EVENT']
    when "pull_request"
        if @payload["action"] == "opened"
            process_pull_request(@payload["pull_request"])
        end

        if @payload["action"] == "reopened"
            process_pull_request(@payload["pull_request"])
        end

        if @payload["action"] == "closed"
            content_type :json
            { :branch => @branch, :response => 'Closed'}.to_json
        end

    end

end

def process_pull_request(pull_request)
    puts "Processing pull request..."
    @client.create_status(pull_request['base']['repo']['full_name'], pull_request['head']['sha'], 'pending', { :description => 'Fighting Wildlings!' })

    # Sycamore School Repo
    # Retreive branch to test
    puts "Update School and get branch"
    puts updateSchool = Shell.execute("cd ~; cd /Volumes/Development/SycamoreSchool; git fetch; git pull; git checkout #{@branch}").success?

    #Sycamore School Rails Repo
    # Update repo to master
    puts "Update Rails Repo"
    puts updateRails = Shell.execute("cd ~; cd /Volumes/Development/SycamoreSchoolRails; git fetch; git pull; git checkout master").success?
    # Update Docker Container
    puts "Update web container"
    puts updateContainer = Shell.execute("cd ~; cd /Volumes/Development/SycamoreSchoolRails; docker-compose build web").success?

    # Sycamore School Tests repo
    # Update repo to master
    puts "Update Tests Repo"
    puts updateTests = Shell.execute("cd ~; cd /Volumes/Development/SycamoreSchoolTests; git fetch; git pull; git checkout master").success?
    # Install dependencies
    puts "Install dependencies"
    puts installDependencies = Shell.execute("cd ~; cd /Volumes/Development/SycamoreSchoolTests; npm install").success?    
    # Start nightwatch tests
    
    if updateSchool && updateRails && updateContainer && updateTests && installDependencies

        puts "Fire Nightwatch!"
        puts nightwatch = Shell.execute("cd ~; cd /Volumes/Development/SycamoreSchoolTests; nightwatch --retries 5").success?

        if nightwatch
            @client.create_status(pull_request['base']['repo']['full_name'], pull_request['head']['sha'], 'success', { :description => 'Nightwatch tests passed!' })
            puts "Pull request processed!"
        else
            @client.create_status(pull_request['base']['repo']['full_name'], pull_request['head']['sha'], 'failure', { :description => 'Nightwatch tests failed somewhere...' })
            puts "Pull request failed..."
        end

    else
        @client.create_status(pull_request['base']['repo']['full_name'], pull_request['head']['sha'], 'error', { :description => 'Something went wrong during build' })
        puts "Something went wrong during build"
    end
    
end
