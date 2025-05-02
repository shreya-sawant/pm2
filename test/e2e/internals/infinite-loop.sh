#!/usr/bin/env bash

SRC=$(cd $(dirname "$0"); pwd)
source "${SRC}/../include.sh"

cd $file_path

echo "Starting infinite loop tests"

$pm2 start killtoofast.js --name unstable-process

echo -n "Waiting for process to restart too many times and pm2 to stop it"

start_time=$(date +%s)

for ((i = 0; i < 900; i++)); do  # 3 minutes max
    status=$($pm2 jlist | jq -r '.[] | select(.name=="unstable-process") | .pm2_env.status')
    echo "Status: $status"

    if [ "$status" == "errored" ]; then
        echo "✔ unstable-process is in errored state"
        break
    fi

    sleep 0.2
done

end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "Process took $elapsed seconds to reach errored state"


$pm2 list
should 'should has stopped unstable process' 'errored' 1

$pm2 delete all

echo "Start infinite loop tests for restart|reload"

cp killnotsofast.js killthen.js

$pm2 start killthen.js --name killthen

$pm2 list

should 'should killthen alive for a long time' 'online' 1

# Replace killthen file with the fast quit file

sleep 15
cp killtoofast.js killthen.js

echo "Restart with unstable process"

$pm2 list

$pm2 restart all  # pm2 reload should also work here

for (( i = 0; i <= 80; i++ )); do
    sleep 0.1
    echo -n "."
done

$pm2 list

should 'should has stoped unstable process' 'errored' 1

rm killthen.js

$pm2 list

$pm2 kill
