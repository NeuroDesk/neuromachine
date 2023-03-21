
# Set password for rdp authentication
/usr/bin/printf '%s\n%s\n' 'password' 'password'| sudo passwd jovyan

# clean up old session files (they prevent the start of the next session):
echo "starting cleanup before if"
if [ -f "/home/jovyan/.ssh/id_rsa" ]
then
    echo "starting cleanup"
    rm /home/jovyan/.ssh/id_rsa
    rm /home/jovyan/.ssh/authorized_keys
    rm /home/jovyan/.ssh/id_rsa.pub
    rm /home/jovyan/.ssh/ssh_host_rsa_key
    rm /home/jovyan/.ssh/ssh_host_rsa_key.pub 
    rm /home/jovyan/.ssh/sshd.pid
    rm /home/jovyan/.Xauthority
    rm -rf /home/jovyan/.dbus/session-bus
    rm -rf /home/jovyan/.vnc
    cp -r /tmp/jovyan/.vnc /home/jovyan/
fi

# update example directory
if [ -d "/home/jovyan/example-notebooks" ]
then
    cd /home/jovyan/example-notebooks
    git pull
else
    git clone https://github.com/NeuroDesk/example-notebooks /home/jovyan/example-notebooks
fi

# cvmfs2 -o config=/cvmfs/neurodesk.ardc.edu.au.conf neurodesk.ardc.edu.au /cvmfs/neurodesk.ardc.edu.au
# ssh-keygen -t rsa -f /home/jovyan/.ssh/id_rsa -b 4096 -m PEM -N '' <<< n
# ssh-keygen -t rsa -f /home/jovyan/.ssh/ssh_host_rsa_key -N '' <<< n
# cat /home/jovyan/.ssh/id_rsa.pub >> /home/jovyan/.ssh/authorized_keys

if [ -z "$CVMFS_DISABLE" ]; then
    echo "\
    ==================================================================
    Mounting CVMFS"
    mkdir -p /cvmfs/neurodesk.ardc.edu.au
    mount -t cvmfs neurodesk.ardc.edu.au /cvmfs/neurodesk.ardc.edu.au

    echo "\
    ==================================================================
    Testing which CVMFS server is fastest"
    cvmfs_talk -i neurodesk.ardc.edu.au host probe
    cvmfs_talk -i neurodesk.ardc.edu.au host info
fi


# export JAVA_OPTS="-Xms512M -Xmx1024M"
# export CATALINA_OPTS="-Xms512M -Xmx1024M"
# service guacd restart
# service xrdp restart
# su jovyan -c "vncserver -depth 24 -geometry 1920x1080 -name \"VNC\" :1"
# su jovyan -c "xset -display :1 s off"