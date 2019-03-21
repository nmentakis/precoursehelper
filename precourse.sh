#!/bin/bash
#
# A little script to make it easier to sync a bunch of precourse repo's at once
# Author: Rob Cornell <rob.cornell@hackreactor.com> or <rob.cornell@gmail.com>
# Updated by: 

# Aug. 28, 2017 - 
# Hi everyone. I made a simple bash script to make it easy to clone/pull repo's for precourse students. 
# Download it to a directory you want to use for precourse stuff, 
# then open it up and fill in the array called GITHUB_HANDLES with your precourse student's handles. 
# Once that's done, run it with "sh precourse.sh" in terminal. 
# It will ask you for a cohort, e.g. "hrnyc11" and a specific repo, if you're only interested in a specific repo. 
# It will then do its best to clone or pull repo's for each student, making directories along the way. 
# Once it's done, it'll print out a list of directories with any new code.

# USAGE: 
# You will have to manually enter the github handles for your students
# in the GITHUB_HANDLES array.

# Ubuntu users will need to run this script using '/bin/bash precourse.sh'

RED=$'\e[31m'
YELLOW=$'\e[33m'
GREEN=$'\e[32m'
COLORLESS=$'\e[0m'

# Update this!
GITHUB_HANDLES=()

# No need to update these
BASE_URL="https://github.com"
PREFIX_REGEXES=(hrnyc[0-9]+ hratx[0-9]+ hrla[0-9]+ hrr[0-9]+ hrsf[0-9]+ rpt[0-9]+)
PRECOURSE_REPOS=(javascript-koans twiddler underbar recursion testbuilder)
UPDATES=()


# Input cohort prefix
read -p "Which cohort prefix do you want to sync with (e.g. hrnyc9): " COHORT_PREFIX

# Input specific repo name, if desired
read -p "Do you want to sync a specific repo (e.g. javascript-koans): " SPECIFIC_REPO

# Evaluate specific repo, if any
if [[ $SPECIFIC_REPO ]]; then 
  for repo in "${PRECOURSE_REPOS[@]}"
  do
    if [[ $repo == $SPECIFIC_REPO ]]; then
      VALID_REPO="true"
    fi
  done

  if ! [ $VALID_REPO ]; then
    echo "${RED}ERROR:${COLORLESS} Invalid repository: ${$SPECIFIC_REPO}"
    exit 1
  fi
fi

# Evaluate the input prefix vs. regexes
for regex in "${PREFIX_REGEXES[@]}"
do
  if [[ $COHORT_PREFIX =~ $regex ]]; then
    VALID_PREFIX="true"
  fi
done

# See if prefix is invalid
if ! [[ $VALID_PREFIX ]]; then
  echo "${RED}ERROR:${COLORLESS} Invalid prefix: ${COHORT_PREFIX}"
  echo "${YELLOW}Please enter a prefix that follows the convention hrnyc##${COLORLESS} (e.g. hrnyc9)"
  exit 1
fi

# Make the cohort directory if necessary
if ! [[ -d $COHORT_PREFIX ]]; then
  mkdir $COHORT_PREFIX
fi
cd $COHORT_PREFIX

# Make the student directory if necessary, then enter it
function enterStudentDirectory()
{
    if ! [[ -d $1 ]]; then
      mkdir $1
    fi
    cd $1
}

function cloneOrPull()  
{
  # Because I hate positional parameters so much
  STUDENT=$1
  REPO=$2
  REPO_DIRECTORY=$3
  FULL_REPO_STRING=$4

  if ! [[ -d $REPO_DIRECTORY ]]; then
    # No local directory for student's fork. Attempt clone
    echo "Trying to clone: ${FULL_REPO_STRING}"
    git clone $FULL_REPO_STRING
    if [ $? -eq 0 ]; then
      echo "${GREEN}Repository cloned: ${STUDENT}/${REPO} ${COLORLESS}"
      var=$(pwd)
      UPDATES+=("(CLONE)  ${var}/${COHORT_PREFIX}-${REPO}")
    else 
      echo "${RED}No fork for ${STUDENT}/${REPO} ${COLORLESS}"
    fi
  else
    # Repo directory exists (fork has been cloned). Attempt pull
    cd $REPO_DIRECTORY # Enter STUDENT's repo directory
    echo "Trying to pull: ${BASE_URL}/${STUDENT}/${COHORT_PREFIX}-${REPO}.git"
    PULLRES=$(git pull)
    if ! [[ $PULLRES == "Already up-to-date." ]]; then 
      var=$(pwd)
      UPDATES+=("(PULL)  ${var}")
    fi
    cd .. # Exit student's repo directory
  fi
}

# Iterate through students only, since specific repo is set
function getSpecificRepo()
{
  for student in "${GITHUB_HANDLES[@]}"
  do
    REPO_DIRECTORY=${COHORT_PREFIX}-${SPECIFIC_REPO}
    FULL_REPO_STRING="${BASE_URL}/${student}/${COHORT_PREFIX}-${SPECIFIC_REPO}.git"

    enterStudentDirectory $student 
    echo $student $SPECIFIC_REPO $REPO_DIRECTORY $FULL_REPO_STRING
    cloneOrPull $student $SPECIFIC_REPO $REPO_DIRECTORY $FULL_REPO_STRING
    cd .. # Exit student directory
  done

  echo CLONED $SPECIFIC_REPO ONLY
}

# Iterate through all students and all repos
function getAllRepos()
{
  for student in "${GITHUB_HANDLES[@]}"
  do 
    enterStudentDirectory $student

    for REPO in "${PRECOURSE_REPOS[@]}"
    do
      REPO_DIRECTORY=${COHORT_PREFIX}-${REPO}
      FULL_REPO_STRING="${BASE_URL}/${student}/${COHORT_PREFIX}-${REPO}.git"

      cloneOrPull $student $REPO $REPO_DIRECTORY $FULL_REPO_STRING
    done
    cd .. # Exit student directory
  done  
}

if [[ $SPECIFIC_REPO ]]; then
  getSpecificRepo $SPECIFIC_REPO
else
  getAllRepos
fi

echo "\n"

if [ ${#UPDATES[@]} -eq 0 ]; then
  echo "${GREEN}No updates.${COLORLESS}"
else
  echo "${GREEN}Updated code in the following directories:${COLORLESS}"
  for update in "${UPDATES[@]}"
  do
    if [[ "$update" == *"koans"* ]]; then
      echo "${update}/KoansRunner.html"
    fi
    if [[ "$update" == *"testbuilder"* ]]; then
      echo "${update}/index.html"
    fi
    if [[ "$update" == *"recursion"* ]]; then
      echo "${update}/SpecRunner.html"
    fi
    if [[ "$update" == *"twittler"* ]]; then
      echo "${update}/index.html"
    fi
    if [[ "$update" == *"underbar"* ]]; then
      echo "${update}/SpecRunner.html"
    fi
  done
  echo "\n"
  echo "${GREEN}You can command-click on the paths above to open each test.${COLORLESS}"
fi


echo "\n"
