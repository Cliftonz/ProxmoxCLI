enum Services {
    pveproxy
    pvedaemon
    spiceproxy
    pvestatd
    pve_cluster
    corosync
    pve_firewall
    pvefw_logger
    pve_ha_crm
    pve_ha_lrm
    sshd
    syslog
    cron
    postfix
    ksmtuned
    systemd_timesyncd
}

enum ServiceState {
    reload
    restart
    start
    stop
}

class Node {

    [string] $Name
    [PSCustomObject] $Subscription
    #[DateTime] $Time
    [PSCustomObject] $Version
    [PSCustomObject] $Status
    [PSCustomObject] $Dns
    
    
    Node ([string] $Name) {
        $this.Name = [string]$Name
        $this.Subscription = $this.getSubscription()
        # Convert UNIX time to Windows time
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
        $this.Time = $origin.AddSeconds(($this.getTime()).localtime)
        $this.Version = $this.getVersion()
        $this.Status = $this.getStatus()
        $this.Dns = $this.getDns()
    }
    
    [void] Refresh() {
        $this.Subscription = $this.getSubscription()
        # Convert UNIX time to Windows time
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
        $this.Time = $origin.AddSeconds(($this.getTime()).localtime)
        $this.Version = $this.getVersion()
        $this.Status = $this.getStatus()
        $this.Dns = $this.getDns()

    }

    [PSCustomObject] getSubscription() {
        return (callREST -Resource "nodes/$($this.Name)/subscription")
    }
    [PSCustomObject] getSyslog() {
        return (callREST -Resource "nodes/$($this.Name)/syslog")
    }
    [PSCustomObject] getTime() {
        return (callREST -Resource "nodes/$($this.Name)/time")
    }
    [PSCustomObject] getVersion() {
        return (callREST -Resource "nodes/$($this.Name)/version")
    }
    [PSCustomObject] getStatus() {
        return (callREST -Resource "nodes/$($this.Name)/status")
    }
    [PSCustomObject] getAplinfo() {
        return (callREST -Resource "nodes/$($this.Name)/aplinfo")
    }
    [PSCustomObject] getDns() {
        return (callREST -Resource "nodes/$($this.Name)/dns")
    }
    [PSCustomObject] getNetstat() {
        return (callREST -Resource "nodes/$($this.Name)/netstat")
    }
    [PSCustomObject] getReport() {
        return (callREST -Resource "nodes/$($this.Name)/report")
    }


    
    # /apt/*
    [PSCustomObject] getAptChangeLog ([String]$package) {
        return (callREST -Resource "nodes/$($this.Name)/apt/changelog" -Options @{name = $package})
    }
    [PSCustomObject] getAptUpdate () {
        return (callREST -Resource "nodes/$($this.Name)/apt/update")
    }
    [PSCustomObject] runAptUpdate ([switch]$notify) {
        $query = "?quiet=true"
        if ($notify) {$query = "$($query)&notify=true"}
        return (callREST -Resource "nodes/$($this.Name)/apt/update$query")
    }
    [PSCustomObject] getAptVersion () {
        return (callREST -Resource "nodes/$($this.Name)/apt/versions")
    }

    # /ceph/*
    # I don't have a ceph setup at the moment to properly write and test this
    [PSCustomObject] getCephFlags () {
        return (callREST -Resource "nodes/$($this.Name)/ceph/flags")
    }
    [PSCustomObject] getCeph () {
        return (callREST -Resource "nodes/$($this.Name)/ceph")
    }
    # TODO: Added everything else once I can get a test rig setup with cephs

    # /disks/*
    [PSCustomObject] getDisks () {
        return (callREST -Resource "nodes/$($this.Name)/disks/list")
    }
    [PSCustomObject] getDisksHealth () {
        return $this.getDisks() | ForEach-Object {
            @{
                'devpath'    = $_.devpath;
                'attributes' = (callREST -Resource "nodes/$($this.Name)/disks/smart" -Options @{disk = $_.devpath}) | Select-Object health
            }
        }
    }
    # TODO: /disks/initgpt POST
    # Required:
    #   disk: string ^/dev/[a-zA-Z0-9]+$
    #   node: string
    # Optional:
    #   uuid: string [a-fA-F0-9\-]+

    # /firewall/*
    # I haven't used this yet, but plan on doing so to get this implimented
    [PSCustomObject] getFirewallLogs ([int]$limit = $null, [int]$start = $null) {
        $query = @{}
        if ($limit -or $start) {
            if ($limit -and $start) {$query = @{limit = $limit; start = $start}
            }
            elseif ($start) {$query = @{start = $start}
            }
            elseif ($limit) {$query = @{limit = $limit}
            }
            return (callREST -Resource "nodes/$($this.Name)/firewall/log" -Options $query)    
        }
        return (callREST -Resource "nodes/$($this.Name)/firewall/log")
    }
    [PSCustomObject] getFirewallOptions () {
        return (callREST -Resource "nodes/$($this.Name)/firewall/options")
    }
    [PSCustomObject] getFirewallRules () {
        return (callREST -Resource "nodes/$($this.Name)/firewall/rules")
    }
    <#
    TODO: /rules POST
     Required:
      action: string [A-Za-z][A-Za-z0-9\-\_]+
      type: enum in,out,group
     Optional:
      enable,pos: int
      comment,dest,digest,iface,macro,proto,source,sport: string
    #>
    <#
    TODO: /rules/{pos} GET
     Optional:
      pos: int
    #>
    <#
    TODO: /rules/{pos} POST
     Required:
     Optional:
      action: string [A-Za-z][A-Za-z0-9\-\_]+
      type: enum in,out,group
      enable,pos,moveto: int
      comment,dest,digest,dport,iface,macro,proto,source,sport: string
    #>
    <#
    TODO: /rules/{pos} DELETE
     Optional:
      digest: string
      pos: int
    #>

    # /lxc/*
    [PSCustomObject] getLxc () {
        return (callREST -Resource "nodes/$($this.Name)/lxc")
    }
    # TODO: impliment this as Qemu was implimented. I might share some of the same code.

    # /network/*
    [PSCustomObject] getNetwork () {
        return (callREST -Resource "nodes/$($this.Name)/network")
    }
    <#
    TODO: /network/{iface} PUT
     Required:
      iface: string
      type: enum bridge,bond,eth,alias,vlan,OVSBridge,OVSBond,OVSPort,OVSInitPort,unknown
     Optional:
      address,address6,bridge_ports,comments,comments6,delete,gateway,gateway6,netmask,slaves: string
      autostart,bridge_vlan_aware: boolean
      bond_mode: enum balance-rr,active-backup,balance-xor,802.3ad,balance-tlb,balance-alb,balance-slb,lacp-balance-slb,lacp-balance-tcp
      bond_xmit_hash_policy: enum layer2,layer2+3,layer3+4
      netmask6: int 0-128
      ovs_bonds,ovs_bridge,ovs_options,ovs_ports: string
      ovs_tags: int 1-4094
    #>
    <#
    TODO: /network/{iface} DELETE
     Required:
      iface: string
    #>
    # /qemu/*
    [PSCustomObject] getQemu () {
        $vms = (callREST -Resource "nodes/$($this.Name)/qemu")
        return $vms | ForEach-Object { [Qemu]::new($this.Name, $_.vmid) }
    }
    # /replication/*
    [PSCustomObject] getReplication () {
        return (callREST -Resource "nodes/$($this.Name)/replication")
    }
    [PSCustomObject] getReplicationLogs ([string]$id = $null, [int]$limit = $null, [int]$start = $null) {
        $query = @{}
        if ($limit -or $start) {
            if ($limit -and $start) {$query = @{limit = $limit; start = $start}
            }
            elseif ($start) {$query = @{start = $start}
            }
            elseif ($limit) {$query = @{limit = $limit}
            }
        }
        if ($id) {
            return (callREST -Resource "nodes/$($this.Name)/replication/$($id)/log" -Options $query)
        }
        return (($this.getReplication()).id | ForEach-Object {callREST -Resource "nodes/$($this.Name)/replication/$($_)/log" -Options $query})
    }
    <#
    TODO: /replication/{id}/schedule_now POST
     Required:
      id: string pve-replication-job-id
    #>
    [PSCustomObject] getReplicationStatus ([string]$id = $null) {
        if ($id) {
            return (callREST -Resource "nodes/$($this.Name)/replication/$($id)/status")
        }
        return (($this.getReplication()).id | ForEach-Object {callREST -Resource "nodes/$($this.Name)/replication/$($_)/status"})
    }
    # /scan/*
    [PSCustomObject] getScan () {
        return (callREST -Resource "nodes/$($this.Name)/scan")
    }
    [PSCustomObject] getScanGlusterFS ([string]$server) {
        return (callREST -Resource "nodes/$($this.Name)/scan/glusterfs" -Options @{server = $server})
    }
    [PSCustomObject] getScanIscsi ([string]$portal) {
        return (callREST -Resource "nodes/$($this.Name)/scan/iscsi" -Options @{portal = $portal})
    }
    [PSCustomObject] getScanLvm () {
        return (callREST -Resource "nodes/$($this.Name)/scan/lvm")
    }
    [PSCustomObject] getScanLvmThin ([string]$vg) {
        if ($vg -match "[a-zA-Z0-9\.\+\_][a-zA-Z0-9\.\+\_\-]+") {
            return (callREST -Resource "nodes/$($this.Name)/scan/lvmthin" -Options @{vg = $vg})
        }
        else {
            return $false
        }
    }
    [PSCustomObject] getScanNfs ([string]$server) {
        return (callREST -Resource "nodes/$($this.Name)/scan/nfs" -Options @{server = $server})
    }
    [PSCustomObject] getScanUsb () {
        return (callREST -Resource "nodes/$($this.Name)/scan/usb")
    }
    [PSCustomObject] getScanZfs () {
        return (callREST -Resource "nodes/$($this.Name)/scan/zfs")
    }
    # /services/*
    [PSCustomObject] getServices () {
        return (callREST -Resource "nodes/$($this.Name)/services")
    }
    [PSCustomObject] getServiceState ([Services]$service) {
        $serviceString = $service.ToString()
        $serviceName = $serviceString.Replace('_', '-')
        return (callREST -Resource "nodes/$($this.Name)/services/$($serviceName)/state")
    }
    [PSCustomObject] setServiceState ([Services]$service, [ServiceState]$state) {
        $serviceString = $service.ToString()
        $serviceName = $serviceString.Replace('_', '-')
        return (callREST -Resource "nodes/$($this.Name)/services/$($serviceName)/$($state)" -Method POST)
    }
    # /storage/*
    [PSCustomObject] getStorage ([switch]$enabled) {
        return (callREST -Resource "nodes/$($this.Name)/storage" -Options @{enabled = $enabled})
    }
    [PSCustomObject] getStorage ([switch]$enabled, [string]$content = $null, [string]$storage = $null, [string]$target = $null) {
        $query = @{
            enabled = $enabled
            content = $content
            storage = $storage
            target  = $target
        }
        return (callREST -Resource "nodes/$($this.Name)/storage" -Options $query)
    }
    # /tasks/*
    [PSCustomObject] getTasks () {
        return (callREST -Resource "nodes/$($this.Name)/tasks")
    }
    # /vzdump/*
    # [PSCustomObject] getVzdump () {
    #     $this.vzdump = (callREST -Resource "nodes/$($this.Name)/vzdump")
    # }

    # /rrd
    #$this.rrd = (callREST -Resource "nodes/$($this.Name)/rrd")
    # /rrddata
    #$this.rrddata = (callREST -Resource "nodes/$($this.Name)/rrddata")
    # /spiceshell
    # $this.spiceshell = (callPost -Resource "nodes/$($this.Name)/spiceshell")
    # /startall
    #$this.startall = (callPost -Resource "nodes/$($this.Name)/startall")
    
    # /stopall
    #$this.stopall = (callPost -Resource "nodes/$($this.Name)/stopall")
    
    # /vncshell
    #$this.vncshell = (callPost -Resource "nodes/$($this.Name)/vncshell")
    # /vncwebsocket
    #$this.vncwebsocket = (callREST -Resource "nodes/$($this.Name)/vncwebsocket")

    # /execute
    [PSCustomObject] execute ($command, $node) {
        #return (callREST -Resource "nodes/$($this.Name)/execute")
        return $false
    }
    # /migrateall
    [PSCustomObject] MigrateAll () {
        #return (callREST -Resource "nodes/$($this.Name)/migrateall")
        return $false
    }
}

enum Features {
    snapshot
    clone
    copy
}

class Qemu {
    
    [string] $vmid
    [PSCustomObject] $AvailableResources
    [PSCustomObject] $Status
    [Node] $Node
        
        
    Qemu ([Node] $Node, [string] $vmid) {
        $this.vmid = $vmid
        $this.Node = $Node
        $this.Refresh()
    }
    Qemu ([String] $Node, [string] $vmid) {
        $this.vmid = $vmid
        $this.Node = [Node]::new($Node)
        $this.Refresh()
    }
    
    [void] Refresh() {
        $this.Status = $this.getStatus()
    }

    [PSCustomObject] getStatus() {
        return (callREST -Resource "nodes/$($this.Node.Name)/qemu/$($this.vmid)/status/current")
    }

    [PSCustomObject] getConfig([switch]$Current) {
        return (callREST -Resource "nodes/$($this.Node.Name)/qemu/$($this.vmid)/config" -Options @{current = $Current})
    }

    [PSCustomObject] getPending() {
        return (callREST -Resource "nodes/$($this.Node.Name)/qemu/$($this.vmid)/pending")
    }

    [PSCustomObject] getFeature([Features]$Feature) {
        return (callREST -Resource "nodes/$($this.Node.Name)/qemu/$($this.vmid)/feature")
    }

    [PSCustomObject] getFeature([Features]$Feature, [string]$SnapName) {
        return (callREST -Resource "nodes/$($this.Node.Name)/qemu/$($this.vmid)/feature" -Options @{snapname = $SnapName})
    }
}