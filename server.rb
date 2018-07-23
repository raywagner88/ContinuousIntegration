require 'sinatra'
require 'json'
require 'octokit'

ACCESS_TOKEN = "" # GitHub OAuth Token

before do
    @client ||= Octokit::Client.new(:access_token => ACCESS_TOKEN)
end

post '/event_handler' do
@payload = JSON.parse(params[:payload])
@branch = @payload["pull_request"]["head"]["ref"]
@answer = false

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
    @client.create_status(pull_request['base']['repo']['full_name'], pull_request['head']['sha'], 'pending')

    sleep 2 # do work...

    if @answer
        @client.create_status(pull_request['base']['repo']['full_name'], pull_request['head']['sha'], 'success')
        puts "Pull request processed!"
    else
        @client.create_status(pull_request['base']['repo']['full_name'], pull_request['head']['sha'], 'failure')
        puts "Pull requst failed "
    end
end
