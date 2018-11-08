#!/bin/bash
declare -r script_run_retries=3

python_install() {
  local VERSIONS="2.7.14.2717"
  FNAME=`wget http://downloads.activestate.com/ActivePython/releases/${VERSIONS}/ -q -O - | grep "linux" | grep "tar.gz"  | head -n 1  | sed -n 's/.*href="\([^"]*\).*$/\1/p'`
  wget http://downloads.activestate.com/ActivePython/releases/${VERSIONS}/${FNAME}
  tar -xzvf ${FNAME}
  # Rename
  mv `find ./ActivePython-* -type d | head -n 1` apy && cd apy && ./install.sh -I /opt/python/
  ln -s /opt/python/bin/easy_install /opt/bin/easy_install
  ln -s /opt/python/bin/pip /opt/bin/pip
  ln -s /opt/python/bin/python /opt/bin/python
  ln -s /opt/python/bin/virtualenv /opt/bin/virtualenv
}

loop=0
if [ ! -f /opt/bin/python ]; then
 echo $loop
while [ $loop -le $script_run_retries ];do
    ((loop++))
    echo "Beginning script run number $loop"
    python_install
    return_code=$?
    if [ $return_code -eq 0 ]; then
      echo "script run number $loop exited with a $return_code"
      break
    fi
    echo "script run number $loop exited with a $return_code"
  done
fi

# Clean up
rm -rf ${FNAME}
rm -rf ${FNAME} apy
