#!/bin/bash
. ${PHDCONST_ROOT}/lib/utils.sh


pacemaker_kill_processes()
{
	local node=$1

	phd_log LOG_DEBUG "Killing processes on $node"

	phd_cmd_exec "killall -q -9 corosync aisexec heartbeat pacemakerd pacemaker-remoted ccm stonithd ha_logd lrmd crmd pengine attrd pingd mgmtd cib fenced dlm_controld gfs_controld" "$node"
}

pacemaker_cluster_stop()
{
	local nodes=$(definition_nodes)
	local node

	for node in $(echo $nodes); do
		phd_cmd_exec "pcs cluster stop" "$node"
		if [ "$?" -eq 0 ]; then
			phd_cmd_exec "service corosync stop" "$node"
		else
			phd_log LOG_ERR "Could not gracefully stop pacemaker on node $node"
			phd_log LOG_DEBUG "Force stopping $node"
		fi
		# always cleanup processes
		pacemaker_kill_processes $node
	done

}

pacemaker_cluster_start()
{
	local nodes=$(definition_nodes)
	local node

	for node in $(echo $nodes); do
		phd_cmd_exec "pcs cluster start" "$node"
		if [ "$?" -ne 0 ]; then
			phd_log LOG_ERR "Could not start pacemaker on node $node"
			exit 1
		fi
	done

	node=$(definition_node "1")

	while true; do
		phd_log LOG_DEBUG "Attempting to determine if pacemaker cluster is up."
		phd_cmd_exec "cibadmin -Q > /dev/null 2>&1" "$nodes"
		if [ "$?" -eq 0 ]; then
			break
		fi
	done
}

pacemaker_cluster_clean()
{
	local nodes=$(definition_nodes)

	phd_cmd_exec "rm -rf /var/lib/pacemaker/cib/* /var/lib/pacemaker/cores/* /var/lib/pacemaker/blackbox/* /var/lib/pacemaker/pengine/*" "$nodes"
}

pacemaker_cluster_init()
{
	local nodes=$(definition_nodes)

	phd_cmd_exec "pcs cluster setup --local phd-cluster $nodes" "$nodes"
	if [ "$?" -ne 0 ]; then
		phd_log LOG_ERR "Could not setup corosync config for pacemaker cluster"
		exit 1
	fi
}
