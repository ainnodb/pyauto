Kubernetes: 
    automatically build kubernetes with shell 
    version v1.22.4 v1.22.3 v1.22.2 v1.22.1 v1.20 v1.21
    
how: put all the kubernetes scripts in same directory.
    prepare the evnvirment setting in < master-savle.sh > from line 10 to 32 ,pls update your setting like master ,work node,etcd server


    #install kubernetes on a single host##
    sh kube st  
        
    ##install kubernet for a cluser with master /slave##
    sh kube ms 