different bash scripts  are there in the folder. 
1. setu the jnekins, once u and running set a user ( admin, admin) for future user
2. Install neccessry plugins
3. Then creating gitlab credentails
4. sonarqube setup  with token then we will use the token for scanning project-  use "complete -cicd-cycle/004_1sonarqube_setup_token.sh"
5. sonar scanner installation 
6. sonar token setup in jenkins credentials
7. creating docker repo password in jenkins credentails 
8. test server permission - while using the test server, if you are not the root user then we need to configure the user to 
docker group to exicute the docker commands. This scrit is doing that(before executing the job only make sure that)

9. we need to configure ssh key in jenkins ( I added ssh manually in jenkins for office system) 
10. Run job creation "complete -cicd-cycle/0010_job_creation_jenkins.sh' then it will deloy the application 

ec2:
run 1 to 7 scripts
then in ec2 instance root user. so no ermission issue
then run the job scrit with job content complete -cicd-cycle/jenkinsfile2-aws. it will deploy application

stage('Stage 4') {
            steps {
                script {
                    // Trigger the second pipeline
                    build job: 'testing-meramerchant'
                }
            }
        }