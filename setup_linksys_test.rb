#!/usr/bin/env ruby

#
# setup new vera
#
# 2012.06 david mayr - first version bash script
# 2013.06 david mayr - new ruby implementation
# 30.08.16 d.thalmeier - integration of new hardware g150 (veraEdge)


require 'rubygems'
require 'active_record'
require 'sequel'
load 'config/environment.rb'
load 'lib/sonnenbatterie.rb'
load 'lib/sonnenbatterie_luup.rb'
STDOUT.sync = true


##############################################################################
# config

version = "3.3" # default version
basedir  = "/srv/vera"
#filesdir = "#{basedir}/files"
filesdir = "#{basedir}/files"
LOGDIRX  = "#{basedir}/log/setup"
logfile  = "#{LOGDIRX}/default.log"
home_template  = "#{basedir}/home-template"
ports_free_dir = "#{basedir}/ports-db/free"
ports_used_dir = "#{basedir}/ports-db/used"
vpn_ip_base = "10.60.0.1"
base_port = nil
sshopts = "-o TCPKeepAlive=yes -o ServerAliveCountMax=5 -o ServerAliveInterval=3 -o ConnectTimeout=20 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
vpn_ip2 = nil


##############################################################################
# functions


def usage( exitcode=0 )
  puts "\nusage/params:\n  <unit serial>  <IP>  [<Port>]"
  puts   "requirements:\n  machine_settings must already contain correct SmartFunction passwd and serial\n\n"
  exit exitcode
end


def out( msg )
  puts "#{msg}"
end


def err( msg, exitcode=nil )
  puts "\nERROR: #{msg}"
  exit exitcode if exitcode
end


def log( msg, logname='default', sb_id='unknown' )
  File.open( "#{LOGDIRX}/#{logname}.log", 'a' ) do |f|
    f.puts "#{Time.now.strftime('%Y.%m.%d %H:%M:%S')} ##{sb_id} #{msg}"
  end
end


def print_data( sb, version )
  puts "----------------------------------------------------------"
  puts "#{sb.branding || 'PSB'} #{sb.psb} (#{sb.product})"
  #puts "    #{sb.anomaly}" if sb.anomaly and sb.anomaly=~/[a-zA-Z0-9!:-]/
  #puts "    #{sb.owner}" if "#{sb.owner}" != ''
  puts "    #{sb.address}" if "#{sb.address}" != ''
  puts "SF: #{sb.vera_serial}  #{sb.vpn_ip}  #{sb.vera_passwd}  #{sb.setup_ip}"
  puts "SF Setup Hardware Version 2.0 (Linksys)" #{version}"
  puts "----------------------------------------------------------\n\n"
end


##############################################################################
# main

#puts "###############################################################"
#puts "################## #{Time.now.strftime('%Y.%m.%d (%a) %H:%M:%S')} ##################"


# ----------------------------------------------------------------------------
# check params
#

# second param: version (optional)
if ARGV[1] =~ /^[.0-9]+$/
  version = ARGV[1].to_s
end
plugindir = "#{basedir}/smartfunction_#{version}_cmh-ludl"
unless File.exist?( plugindir )
  err( "SCP ERROR for plugin files: source '#{plugindir}' or SF plugin version '#{version}' does not exist.", 32 )
end


# first param: serial
sb_id = ARGV[0]
case sb_id
when '-h'
when '--help'
  usage(0)
when /^[0-9]{2,6}$/
  sb = Sonnenbatterie.new( sb_id )
  logfile = "#{LOGDIRX}/#{sb_id}.log"
  err( "cannot get data from database for ID #{sb_id}", 1 ) unless sb
  sf_ip   = sb.setup_ip.split(/:/)[0] if sb.setup_ip
  sf_port = sb.setup_ip.split(/:/)[1] || "22" if sb.setup_ip
  err( "No or wrong Setup IP for unit ##{sb_id}." ,   2 ) if sf_ip !~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/
  err( "No or wrong Setup PORT for unit ##{sb_id}." , 2 ) if sf_port and sf_port != '' and sf_port !~ /^[0-9]{2,5}$/
  print_data( sb, version )
else usage(1)
end


# ----------------------------------------------------------------------------
# check sb data
#
if sb.vera_serial !~ /^[0-9]{8}$/
  unless sb.vera_serial =~ /openwrt/i
    err( "SmartFunction serial ID wrong or missing for unit ##{sb_id} (#{sb.vera_serial.inspect})." , 2 )
  end
end
if sb.vera_passwd !~ /^[a-zA-Z0-9]{8,32}$/ and  sb.vera_serial !~ /openwrt/i
  err( "SmartFunction password wrong or missing for unit ##{sb_id}." , 2 )
end
if sb.vpn_ip =~ /[0-9.]*:[0-9]{4,5}/
  out( "WARNING: SmartFunction VPN-IP (#{sb.vpn_ip}) is already IN USE - see unit ##{sb_id}.\n\n" )
end



# ----------------------------------------------------------------------------
# check connectivity
#
result = %x( nmap -oG - -p#{sf_port} #{sf_ip} | grep -v ^# | grep "#{sf_port}/open/tcp" )
err( "Connection Error: SmartFunction unreachable via #{sf_ip} on port #{sf_port} .", 9 ) if $?.exitstatus != 0



# ----------------------------------------------------------------------------
# remove known hosts entry in case already existing
#
%x{ [ "$(ssh-keygen -F #{sf_ip})" ] && ssh-keygen -R #{sf_ip} >/dev/null 2>&1 }



# ----------------------------------------------------------------------------
# install ssh key
#
print "Transfer SSH pubkey to SmartFunction: "
result = %x( sshpass -p '#{sb.vera_passwd}' scp -P #{sf_port} #{filesdir}/etc/dropbear/authorized_keys root@#{sf_ip}:/etc/dropbear/ )
case $?.exitstatus
when 5 then err "ERROR: wrong password for unit ##{sb_id} or wrong Setup IP!"
when 0 then out "OK"
else err( "ERROR: sshpass exitstatus: #{$?.exitstatus}", 8 )
end
puts






































# ----------------------------------------------------------------------------
# check if vpn2 key already available
#
print "Checking if 10.64-VPN cert already exists: "
result = %x( ssh -p #{sf_port} root@#{sf_ip} 'cd /etc/openvpn/ ; keycount=$(ls -1 vpnclient.*.key 2>/dev/null | wc -l) ; echo "$keycount:$(hostname)"' ).chomp
case $?.exitstatus
when 0 then
  keycount = result.split(':')[0].to_i
  hostname = result.split(':')[1]
  log "keycount=#{keycount},hostname=#{hostname}", 'vpn_ip2', sb_id

  if keycount.to_i > 0

    # print warning and do NOT copy a new cert to the SF
    if keycount.to_i > 1
      out "\n    WARNING: SF #{hostname} has already #{keycount}(!) certs, will not copy a new one"
    else
      out "\n    WARNING: SF #{hostname} has already a cert, will not copy a new one"
    end

  else # no cert on SF yet
    out "no, needs cert"

    # ----------------------------------------------------------------------------
    # select & copy openvpn cert/key (NEW VPN)
    #
    certdir = "/srv/vera/certs"
    print "Choosing next free 10.64-VPN cert: "

    available_cert = %x( ls -1 #{certdir}/available/10.64.*.tar.gz | sort -V | head -n1 ).chomp
    if $?.exitstatus == 0 and File.exists?( available_cert )
      out "OK  (#{available_cert})"
    else
      err( "ERROR: no more certificates available in #{certdir}/available. Abort. exitstatus: #{$?.exitstatus}", 3 )
    end
    
    log "available_cert=#{available_cert}", 'vpn_ip2', sb_id

    if File.exists?(available_cert)

      certname = File.basename( available_cert ).gsub( /\.tar\.gz$/, '')
      certfile = "#{certdir}/in_setup_process/#{certname}.tar.gz"
      vpn_ip2 = certname.to_s

      # move to temp dir to avoid letting others take it in the meantime
      #
      print "Reserving next free IP/cert #{certname} ... "
      moveresult = %x( mv #{available_cert} #{certdir}/in_setup_process/ )
      case $?.exitstatus
      when 0 then out "OK"
      else err( "ERROR: unable move cert  #{available_cert} to in_setup_process dir - maybe another processes took it meanwhile. exitstatus: #{$?.exitstatus}", 3 )
      end

      # copy cert to SF
      #
      print "Transfer 10.64-VPN cert #{certname} to SmartFunction: "
      sf_hostname = %x( zcat "#{certfile}" | ssh #{sshopts} -p#{sf_port} root@#{sf_ip} 'mkdir -p /etc/openvpn && cd /etc/openvpn && tar -xf - ; hostname' ).chomp
      ec=$?.exitstatus
      log "sf_hostname=#{sf_hostname},vpn_ip2=#{vpn_ip2},certfile=#{certfile},exitstatus=#{ec}", 'vpn_ip2', sb_id
      case ec
      when 0 then out "OK  (SF-ID: #{sf_hostname})"

        moveresult2 = %x( mv #{certfile} #{certdir}/in_use/ && ln -s #{certname}.tar.gz #{certdir}/in_use/#{certname}.tar.gz_#{Time.now.strftime '+%Y.%m.%d-%H.%M.%S'}_sf-#{sf_hostname}_sb-#{sb_id} )
        if $?.exitstatus != 0
          err( "ERROR: unable move cert  #{certfile} to in_use/ dir - maybe another processes took it meanwhile. exitstatus: #{$?.exitstatus}", 3 )
        end

      else
        vpn_ip2 = nil # reset vpn_ip2 if transferring fails!
        err( "ERROR: transferring  10.64-VPN cert #{certname} in #{certfile} to SF-ID: #{sf_hostname}, exitstatus: #{ec}", 3 )
      end
    else
      err( "ERROR: 10.64-VPN cert #{available_cert} does not exist.", 99 )
    end

  end


else err( "ERROR: checking for already existing 10.64-VPN certs: #{result} exitstatus: #{$?.exitstatus}", 3 )
end



















# ----------------------------------------------------------------------------
# copy files
#
print "Transfer  base  files to SmartFunction: "
files = %w( etc/init.d/* etc/prosol/* root/.profile etc/config/* etc/openvpn/* etc/firewall.user )
result = %x( cd #{filesdir} ; tar -cf - #{files.join(' ')} | ssh -p#{sf_port} root@#{sf_ip} "cd / && tar -xf -" )
case $?.exitstatus
when 0 then out "OK"
else err( "ERROR: transferring base files: exitstatus: #{$?.exitstatus}", 3 )
end

print "Install packages: "
result = %x( ssh -p#{sf_port} root@#{sf_ip} "opkg update ; opkg install curl coreutils-stat" )
case $?.exitstatus
when 0 then out "OK"
else err( "ERROR: installing packages: exitstatus: #{$?.exitstatus}", 3 )
end

#print "Transfer plugin files to SmartFunction: "
#result = %x( cd #{plugindir} ; tar --exclude=.svn -cf - * | ssh -p#{sf_port} root@#{sf_ip} "mkdir -p /etc/cmh-ludl ; cd /etc/cmh-ludl && tar -xf -" )
#case $?.exitstatus
#when 0 then out "OK"
#else err( "ERROR: transferring plugin files: exitstatus: #{$?.exitstatus}", 3 )
#end



# ----------------------------------------------------------------------------
# run setup scripts
#
out "\nStarting setup scripts on SmartFunction - please be patient, takes about one minute... "
setup_result = ""
setup_script_cmd = "ssh -p#{sf_port} root@#{sf_ip} 'cd /etc/prosol && ./setup-openvpn'"
IO.popen( setup_script_cmd ) do |io|
  while ( line = io.gets ) do 
    puts line 
    setup_result << line
  end
end

case $?.exitstatus
when 0
  puts

  # OBSOLETE ssh-tunnel:
  #
  ## set ssh-tunnel ip:port in ticket
  #if base_port
  #  vpn_ip_new = "#{vpn_ip_base}:#{base_port}"
  #  if base_port and sb.vpn_ip = vpn_ip_new
  #    out("VPN IP von # #{sb_id} auf #{vpn_ip_new} eingestellt.")
  #  else
  #    err( "Setzen von VPN IP #{vpn_ip_new} auf # #{sb_id} fehlgeschlagen, bitte manuell eintragen", 13 )
  #  end
  #end


  # set vpn_ip2 in portal
  #
  vpn_ip2_from_setup = setup_result.to_s.split("\n").select{|l| l =~ /key to be used:/ }.first.sub( /^.*vpnclient\.v1\.([.0-9]*)\.key$/ , '\1' )
  old_vpn_ip2 = %x( vpn_ip2 #{sb_id} ).to_s.chomp
  old_vpn_ip2 = nil if old_vpn_ip2.length < 7 or old_vpn_ip2 == vpn_ip2_from_setup or old_vpn_ip2 == vpn_ip2
  if vpn_ip2 and vpn_ip2.to_s.length>7
    out("Setting 10.64-VPN IP in Portal for serial ##{sb_id} to: #{vpn_ip2}  #{'(was '+old_vpn_ip2+' before)' if old_vpn_ip2}")
    result = %x( vpn_ip2 #{sb_id} #{vpn_ip2} 2>&1 )
    log("sb_id=#{sb_id},vpn_ip2=#{vpn_ip2},result=#{result}", 'vpn_ip2', sb_id )
  else
    if vpn_ip2_from_setup.to_s.length>7
      out("Setting 10.64-VPN IP in Portal for serial ##{sb_id} to: #{vpn_ip2_from_setup}  (from setup result)  #{'(was '+old_vpn_ip2+' before)' if old_vpn_ip2}")
      result = %x( vpn_ip2 #{sb_id} #{vpn_ip2_from_setup} 2>&1 )
      log("sb_id=#{sb_id},vpn_ip2_from_setup=#{vpn_ip2_from_setup},result=#{result}", 'vpn_ip2', sb_id )
    else
      out("NOT setting 10.64-VPN IP in Portal for serial ##{sb_id}, did not setup a 10.64-VPN.")
      log("sb_id=#{sb_id},vpn_ip2=unchanged", 'vpn_ip2', sb_id)
    end
  end

  out "\nDONE    v=#{version}    #{Time.now.strftime('%Y.%m.%d  %H:%M:%S  %Z (%z)')}\n"
  %{ssh -p #{sf_port} root@#{sf_ip} 'reboot'}
else err( "exitstatus=#{$?.exitstatus}", 7 )
end






#print "Transfer SSH pubkey to SmartFunction: "
#result = %x( sshpass -p '#{sb.vera_passwd}' scp -P #{sf_port} #{filesdir}/etc/dropbear/authorized_keys root@#{sf_ip}:/etc/dropbear/ )
#case $?.exitstatus
#when 5 then err "ERROR: wrong password for unit ##{sb_id} or wrong Setup IP!"
#when 0 then out "OK"
#else err( "ERROR: sshpass exitstatus: #{$?.exitstatus}", 8 )
#end



out "\nlinksys setup started : "

out "\nfile transfer from vpn server to linksys router"
result = %x(scp /srv/vera/setup_linksys_files/installation/packaging/setup.tar root@#{sf_ip}:/tmp)
case $?.exitstatus
when 0 then out "OK"
else err("Transfering file fron vpn server to linksys")
end

out "\nsetup linksys router"
result = %x( ssh root@#{sf_ip} 'tar xf /tmp/setup.tar -C /tmp ; /tmp/setup.sh' ).chomp
case $?.exitstatus
when 0 then out "OK"
else err("installation interrupt into linksys")
end

update = %x(ssh root@#{sf_ip} 'opkg update')
install = %x( ssh root@#{sf_ip} 'opkg install openvpn-openssl')
result= %( ssh root@#{sf_ip} '/etc/init.d/openvpn start')
out update
out install
out result

out "\nlinksys setup finished"

