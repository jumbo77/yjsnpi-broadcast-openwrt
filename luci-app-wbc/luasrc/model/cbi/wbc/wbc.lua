-- YJSNPI-Broadcast
-- Another EZ-WifiBroadcast Mod
-- Dirty mod by @libc0607 (libc0607@gmail.com)

m = Map("wbc", translate("YJSNPI-Broadcast"), 
			translate("Another <a href=\"https://github.com/rodizio1/EZ-WifiBroadcast\">rodizio1/EZ-WifiBroadcast</a> Mod")
			.."<br />"..translate("Kusai Digital HD Video Transmission")
			.."<br />"..translate("<a href=\"https://github.com/libc0607/YJSNPI-Broadcast\">Github Homepage</a>")
			)

require "luci.sys"
require "nixio.fs"

-- add all possible frequency to freq_list
local wlan_dev_list = {}
local freq_list = {}
for k, v in ipairs(luci.sys.net.devices()) do
	if string.match(v, "wlan") then
		wlan_dev_list[#wlan_dev_list+1] = v
		local iwi = luci.sys.wifi.getiwinfo(v)
		for i,j in ipairs(iwi.freqlist) do 
			freq_list[#freq_list+1] = iwi.freqlist[i].mhz 
		end
	end
end
-- Get all /dev/tty* to tty_list
local tty_list = {}
for e in nixio.fs.dir("/dev") do 
	if string.match(e, "tty") then
		tty_list[#tty_list+1] = "/dev/"..e
	end
end

-- wbc.wbc: Global settings
s_wbc = m:section(TypedSection, "wbc", translate("YJSNPI-Broadcast Settings"))
s_wbc.anonymous = true
s_wbc.addremove = false
-- wbc.wbc.enable: Enable
o_wbc_enable = s_wbc:option(Flag, "enable", translate("Enable YJSNPI-Broadcast"))
o_wbc_enable.rmempty = false
-- wbc.wbc.confpath: config file on HTTP
-- Note: 	this file is for raspi; will be link to /www 
--			e.g. when set to '/wbc-config.ini'
--			on raspi run 'wget 192.168.1.1/wbc-config.ini'
o_wbc_confpath = s_wbc:option(Value, "confpath", translate("Config file on HTTP"))
o_wbc_confpath.default = '/wbc-config.ini'
o_wbc_confpath:depends("enable", 1)



-- wbc.nic: Wi-Fi settings
s_nic = m:section(TypedSection, "nic", translate("Wi-Fi Settings"))
s_nic.anonymous = true
s_nic.addremove = false
-- wbc.nic.iface: Wireless Interface
o_nic_iface = s_nic:option(Value, "iface", translate("Wireless Interface"))
o_nic_iface.rmempty = false
for k,v in ipairs(wlan_dev_list) do 
	o_nic_iface:value(v) 
end
o_nic_iface.default = "wlan0"
-- wbc.nic.freq: Frequency
o_nic_freq = s_nic:option(Value, "freq", translate("Center Frequency"))
o_nic_freq.rmempty = false
for k,v in ipairs(freq_list) do 
	o_nic_freq:value(v, v.." MHz") 
end
o_nic_freq.default = 2437
-- wbc.nic.mixer_enable: External Mixer Enable
o_nic_mixer_enable = s_nic:option(Flag, "mixer_enable", translate("Enable External Mixer"))
o_nic_mixer_enable.rmempty = false
-- wbc.nic.mixer_uart: External Mixer UART Interface
o_nic_mixer_uart = s_nic:option(ListValue, "mixer_uart", translate("External Mixer UART Interface"))
for k,v in ipairs(tty_list) do 
	o_nic_mixer_uart:value(v) 
end
o_nic_mixer_uart.default = "/dev/ttyUSB1"
o_nic_mixer_uart:depends("mixer_enable", 1)
-- wbc.nic.mixer_freq: External Mixer LO Frequency
o_nic_mixer_freq = s_nic:option(Value, "mixer_freq", translate("Mixer LO Frequency (kHz, 85000~2700000, step 10kHz)"))
o_nic_mixer_freq.rmempty = false
o_nic_mixer_freq.default = 2000000
o_nic_mixer_freq:depends("mixer_enable", 1)
-- wbc.nic.chanbw: Channel Bandwidth
o_nic_chanbw = s_nic:option(ListValue, "chanbw", translate("Channel Bandwidth"), translate("Note: ath9k only"))
o_nic_chanbw.rmempty = false
o_nic_chanbw:value(5,  "5 MHz")
o_nic_chanbw:value(10, "10 MHz")
o_nic_chanbw:value(20, "20 MHz")
o_nic_chanbw.default = 20
-- wbc.nic.txpcust: Use Custom TX Power
o_nic_txpcust = s_nic:option(Flag, "txpcust", translate("Use Custom TX Power (ath9k only)"), 
									translate("Note: ath9k only; Too high will cause high EVM and/or burn your card & PA; External PAs/Attenuators not included."))
o_nic_txpcust.rmempty = false
-- wbc.nic.txph: High rate level TX Power (ath9k only)
o_nic_txph = s_nic:option(ListValue, "txph", translate("High rate level TX Power"))
o_nic_txph.rmempty = false
o_nic_txph.datatype = "range(0,30)"
o_nic_txph:depends("txpcust", 1)
for i = 0, 30 do o_nic_txph:value(i, i.." dBm") end
o_nic_txph.default = 20
-- wbc.nic.txpl: Low rate level TX Power (ath9k only)
o_nic_txpl = s_nic:option(ListValue, "txpl", translate("Low rate level TX Power"))
o_nic_txpl.rmempty = false
o_nic_txpl.datatype = "range(0,30)"
o_nic_txpl:depends("txpcust", 1)
for i = 0, 30 do o_nic_txpl:value(i, i.." dBm") end
o_nic_txpl.default = 20
-- wbc.nic.txrh: High rate level (ath9k only)
o_nic_txrh = s_nic:option(ListValue, "txrh", translate("High rate level"))
o_nic_txrh.default = "n:3"
o_nic_txrh:value("b:5",  	"5.5 Mbps (802.11b, CCK)")
o_nic_txrh:value("b:11", 	"11 Mbps (802.11b, CCK)")
o_nic_txrh:value("g:6",     "6 Mbps (802.11g, BPSK, 1/2)")
o_nic_txrh:value("g:9", 	"9 Mbps (802.11g, BPSK, 3/4)")
o_nic_txrh:value("g:12", 	"12 Mbps (802.11g, QPSK, 1/2)")
o_nic_txrh:value("g:18", 	"18 Mbps (802.11g, QPSK, 3/4)")
o_nic_txrh:value("g:24", 	"24 Mbps (802.11g, 16-QAM, 1/2)")
o_nic_txrh:value("g:36", 	"36 Mbps (802.11g, 16-QAM, 3/4)")
o_nic_txrh:value("n:0", 	"MCS 0 (6.5 Mbps, 1x1, BPSK, 1/2)")
o_nic_txrh:value("n:1", 	"MCS 1 (13.0 Mbps, 1x1, QPSK, 1/2)")
o_nic_txrh:value("n:2", 	"MCS 2 (19.5 Mbps, 1x1, QPSK, 3/4)")
o_nic_txrh:value("n:3", 	"MCS 3 (26.0 Mbps, 1x1, 16-QAM, 1/2)")
o_nic_txrh:value("n:4", 	"MCS 4 (39.0 Mbps, 1x1, 16-QAM, 3/4)")
-- wbc.nic.txrl: Low rate level (ath9k only)
o_nic_txrl = s_nic:option(ListValue, "txrl", translate("Low rate level"))
o_nic_txrl.default = "n:0"
o_nic_txrl:value("b:1",  	"1 Mbps (802.11b, DSSS)")
o_nic_txrl:value("b:2",  	"2 Mbps (802.11b, DSSS)")
o_nic_txrl:value("b:5",  	"5.5 Mbps (802.11b, CCK)")
o_nic_txrl:value("b:11", 	"11 Mbps (802.11b, CCK)")
o_nic_txrl:value("g:6",     "6 Mbps (802.11g, BPSK, 1/2)")
o_nic_txrl:value("g:9", 	"9 Mbps (802.11g, BPSK, 3/4)")
o_nic_txrl:value("g:12", 	"12 Mbps (802.11g, QPSK, 1/2)")
o_nic_txrl:value("n:0", 	"MCS 0 (6.5 Mbps, 1x1, BPSK, 1/2)")
o_nic_txrl:value("n:1", 	"MCS 1 (13.0 Mbps, 1x1, QPSK, 1/2)")
-- wbc.nic.ldpc: enable LDPC of 802.11n rate
o_nic_ldpc = s_nic:option(Flag, "ldpc", translate("enable LDPC of 802.11n rate"), 
									translate("Make sure both TX & RX support it."))
o_nic_ldpc.rmempty = false
-- wbc.nic.stbc: enable STBC of 802.11n rate
o_nic_stbc = s_nic:option(Flag, "stbc", translate("enable STBC of 802.11n rate"), 
									translate("Make sure both TX & RX support it."))
o_nic_stbc.rmempty = false
for i=0,7 do 
	o_nic_ldpc:depends("txrh", "n:"..i)
	o_nic_ldpc:depends("txrl", "n:"..i)
	o_nic_stbc:depends("txrh", "n:"..i)
	o_nic_stbc:depends("txrl", "n:"..i)
end

-- wbc.video: Video transfer settings
s_video = m:section(TypedSection, "video", translate("Video Transfer Settings"))
s_video.anonymous = true
s_video.addremove = false
-- wbc.video.enable: Video Transfer Enable
o_video_enable = s_video:option(Flag, "enable", translate("Enable Video Transfer"))
o_video_enable.rmempty = false
-- wbc.video.mode: Video Transfer Mode
o_video_mode = s_video:option(ListValue, "mode", translate("Transfer Mode"))
o_video_mode.rmempty = false
o_video_mode:value("tx", translate("Transceiver"))
o_video_mode:value("rx", translate("Receiver"))
o_video_mode.default = "tx"
o_video_mode:depends("enable", 1)
-- wbc.video.listen_port: Listen on port
o_video_listen_port = s_video:option(Value, "listen_port", translate("Listen On Local Port"))
o_video_listen_port.datatype = "portrange(1024,65535)"
o_video_listen_port:depends("mode", "tx")
o_video_listen_port.placeholder = 35000
o_video_listen_port.default = 35000
-- wbc.video.send_ip_port: Send Video Stream to IP:Port
o_video_send_ip_port = s_video:option(Value, "send_ip_port", translate("Send Video Stream to IP:Port"))
o_video_send_ip_port.datatype = "ipaddrport"
o_video_send_ip_port:depends("mode", "rx")
-- wbc.video.alive_send_ip_port: Send check alive msg to IP:Port
o_video_alive_send_ip_port = s_video:option(Value, "alive_send_ip_port", translate("Send Alive Msg to IP:Port"))
o_video_alive_send_ip_port.datatype = "ipaddrport"
o_video_alive_send_ip_port:depends("mode", "rx")
-- wbc.video.datanum: Data packets in a block
o_video_datanum = s_video:option(Value, "datanum", translate("Data packets in a block"))
o_video_datanum.default = 8
o_video_datanum.datatype = "range(1,32)"
o_video_datanum.placeholder = 8
o_video_datanum:depends("enable", 1)
-- wbc.video.fecnum: FEC packets in a block
o_video_fecnum = s_video:option(Value, "fecnum", translate("FEC packets in a block"))
o_video_fecnum.default = 4
o_video_fecnum.datatype = "range(1,32)"
o_video_fecnum.placeholder = 4
o_video_fecnum:depends("enable", 1)
-- wbc.video.packetsize: Bytes per packet
o_video_packetsize = s_video:option(Value, "packetsize", translate("Bytes per packet"))
o_video_packetsize.default = 1024
o_video_packetsize.placeholder = 1024
o_video_packetsize.datatype = "range(32,1450)"
o_video_packetsize:depends("enable", 1)
-- wbc.video.frametype: Frame Type
o_video_frametype = s_video:option(ListValue, "frametype", translate("Wireless Frame Type"))
o_video_frametype:value(0, "DATA Short")
o_video_frametype:value(1, "DATA Standard")
o_video_frametype:value(2, "RTS")
o_video_frametype.default = 0
o_video_frametype:depends("enable", 1)
-- wbc.video.rxbuf: RX Buf Size
o_video_rxbuf = s_video:option(Value, "rxbuf", translate("RX Buf Size"))
o_video_rxbuf.default = 0
o_video_rxbuf.placeholder = 0
o_video_rxbuf.datatype = "range(0,32)"
o_video_rxbuf:depends("mode", "rx")
-- wbc.video.fps: Video FPS
o_video_fps = s_video:option(ListValue, "fps", translate("Video FPS"), translate("Make sure that both your screen and camera support that rate"))
o_video_fps.default = 48
o_video_fps.placeholder = 48
o_video_fps:value(30, "30 fps")
o_video_fps:value(40, "40 fps")
o_video_fps:value(48, "48 fps")
o_video_fps:value(59.9, "59.9 fps")
o_video_fps:value(60, "60 fps")
o_video_fps:value(90, "90 fps")
o_video_fps:value(120, "120 fps")
o_video_fps:value(144, "144 fps")
o_video_fps:value(240, "240 fps")
o_video_fps:depends("enable", 1)
-- wbc.video.imgsize: Video resolution
o_video_imgsize = s_video:option(ListValue, "imgsize", translate("Img Size (resolution)"))
o_video_imgsize.default = "1280x720"
o_video_imgsize.placeholder = "1280x720"
o_video_imgsize:value("240x144")
o_video_imgsize:value("480x272")
o_video_imgsize:value("800x480")
o_video_imgsize:value("1280x720")
o_video_imgsize:value("1640x922")
o_video_imgsize:value("1920x1080")
o_video_imgsize:depends("mode", "tx")
-- wbc.video.bitrate: Bitrate
o_video_bitrate = s_video:option(Value, "bitrate", translate("Video Bitrate (kbit/s)"), "<a href='"..luci.dispatcher.build_url("admin/wbc/tx_measure").."'>"..translate("Perform tx_measure with saved config").."</a>")
o_video_bitrate.default = 2000
o_video_bitrate.placeholder = 2000
o_video_bitrate.datatype = "range(100,16000)"
o_video_bitrate:depends("enable", 1)
-- wbc.video.keyframerate: Keyframe Rate
o_video_keyframerate = s_video:option(Value, "keyframerate", translate("Key Frame Rate"))
o_video_keyframerate.default = 5
o_video_keyframerate.placeholder = 5
o_video_keyframerate.datatype = "range(2,10)"
o_video_keyframerate:depends("mode", "tx")
-- wbc.video.extraparams: raspivid Extra Params
o_video_extraparams = s_video:option(Value, "extraparams", translate("raspivid Extra Params"), "<a href='https://github.com/rodizio1/EZ-WifiBroadcast/wiki/Expert-~-Raspivid-camera-settings'>"..translate("Learn more").."</a>")
o_video_extraparams.default = '-cd H264 -n -fl -ih -pf high -if both -ex sports -mm average -awb horizon'
o_video_extraparams.placeholder = '-cd H264 -n -fl -ih -pf high -if both -ex sports -mm average -awb horizon'
o_video_extraparams:depends("mode", "tx")
-- wbc.video.save_enable: Video Save Enable
o_video_save_enable = s_video:option(Flag, "save_enable", translate("Enable Video Save"))
o_video_save_enable.rmempty = false
o_video_save_enable:depends("mode", "rx")
-- wbc.video.savepath: Save Raw Video To Path
o_video_savepath = s_video:option(Value, "savepath", translate("Save Raw Video To Path"))
o_video_savepath.default = '/mnt/sda1/wbc_video'
o_video_savepath.placeholder = '/mnt/sda1/wbc_video'
o_video_savepath:depends("save_enable", 1)
-- wbc.video.sysair_forward_port: shmem sysair forward listen udp port
o_video_sysair_forward_port = s_video:option(Value, "sysair_forward_port", translate("shmem sysair forward listen udp port"))
o_video_sysair_forward_port.rmempty = false
o_video_sysair_forward_port.datatype = "portrange(1024,65535)"
o_video_sysair_forward_port:depends("mode", "tx")
o_video_sysair_forward_port.placeholder = 34999
o_video_sysair_forward_port.default = 34999
-- wbc.video.encrypt_enable: Video Encrypt Enable
o_video_encrypt_enable = s_video:option(Flag, "encrypt_enable", translate("Encrypt"), translate("May cause high CPU load"))
o_video_encrypt_enable.rmempty = false
o_video_encrypt_enable:depends("enable", 1)
-- wbc.video.password: Encrypt Password
o_video_encrypt_password = s_video:option(Value, "encrypt_password", translate("Password"))
o_video_encrypt_password.rmempty = false
o_video_encrypt_password.password = true
o_video_encrypt_password:depends("encrypt_enable", 1)
-- wbc.video.ratelevel: video transmission rate level
o_video_ratelevel = s_video:option(ListValue, "ratelevel", translate("video transmission rate level"))
o_video_ratelevel.rmempty = false
o_video_ratelevel:value("H", translate("High rate (Low power)"))
o_video_ratelevel:value("L", translate("Low rate (High power)"))
o_video_ratelevel.default = "L"
o_video_ratelevel:depends("mode", "tx")

-- wbc.rssi: RSSI settings
s_rssi = m:section(TypedSection, "rssi", translate("RSSI Settings"))
s_rssi.anonymous = true
s_rssi.addremove = false
-- wbc.rssi.enable: RSSI Enable
o_rssi_enable = s_rssi:option(Flag, "enable", translate("Enable RSSI"))
o_rssi_enable.rmempty = false
-- wbc.rssi.mode: RSSI Transfer Mode
o_rssi_mode = s_rssi:option(ListValue, "mode", translate("Transfer Mode"))
o_rssi_mode.rmempty = false
o_rssi_mode:value("tx", translate("Transceiver"))
o_rssi_mode:value("rx", translate("Receiver"))
o_rssi_mode.default = "tx"
o_rssi_mode:depends("enable", 1)
-- wbc.rssi.send_ip_port: RSSI RX Data Send to IP:Port	(rssi_forward/rssi_forward_in)
o_rssi_send_ip_port = s_rssi:option(Value, "send_ip_port", translate("Send RSSI Data to IP:Port"))
o_rssi_send_ip_port.datatype = "ipaddrport"
o_rssi_send_ip_port:depends("mode", "rx")
-- wbc.rssi.encrypt_enable: rssi Encrypt Enable
o_rssi_encrypt_enable = s_rssi:option(Flag, "encrypt_enable", translate("Encrypt"))
o_rssi_encrypt_enable.rmempty = false
o_rssi_encrypt_enable:depends("enable", 1)
-- wbc.rssi.password: Encrypt Password
o_rssi_encrypt_password = s_rssi:option(Value, "encrypt_password", translate("Password"))
o_rssi_encrypt_password.rmempty = false
o_rssi_encrypt_password.password = true
o_rssi_encrypt_password:depends("encrypt_enable", 1)
-- wbc.rssi.rssifreq: RSSI refresh freq (Hz)
o_rssi_rssifreq = s_rssi:option(Value, "rssifreq", translate("RSSI refresh freq (Hz)"))
o_rssi_rssifreq.default = 3
o_rssi_rssifreq.placeholder = 3
o_rssi_rssifreq.datatype = "range(2,10)"
o_rssi_rssifreq:depends("mode", "tx")
-- wbc.rssi.ratelevel: RSSI transmission rate level
o_rssi_ratelevel = s_rssi:option(ListValue, "ratelevel", translate("RSSI transmission rate level"))
o_rssi_ratelevel.rmempty = false
o_rssi_ratelevel:value("H", translate("High rate (Low power)"))
o_rssi_ratelevel:value("L", translate("Low rate (High power)"))
o_rssi_ratelevel.default = "L"
o_rssi_ratelevel:depends("mode", "tx")

-- wbc.telemetry: Telemetry settings
s_telemetry = m:section(TypedSection, "telemetry", translate("Telemetry Settings"))
s_telemetry.anonymous = true
s_telemetry.addremove = false
-- wbc.telemetry.enable: Telemetry Enable
o_telemetry_enable = s_telemetry:option(Flag, "enable", translate("Enable Telemetry"))
o_telemetry_enable.rmempty = false
-- wbc.telemetry.mode: Telemetry Transfer Mode
o_telemetry_mode = s_telemetry:option(ListValue, "mode", translate("Transfer Mode"))
o_telemetry_mode.rmempty = false
o_telemetry_mode:value("tx", translate("Transceiver"))
o_telemetry_mode:value("rx", translate("Receiver"))
o_telemetry_mode.default = "tx"
o_telemetry_mode:depends("enable", 1)
-- wbc.telemetry.uart: Telemetry UART Interface
o_telemetry_uart = s_telemetry:option(ListValue, "uart", translate("Telemetry UART Interface"))
for k,v in ipairs(tty_list) do 
	o_telemetry_uart:value(v) 
end
o_telemetry_uart.default = "/dev/ttyUSB0"
o_telemetry_uart:depends("enable", 1)
-- wbc.telemetry.baud: Telemetry UART Baud rate
o_telemetry_baud = s_telemetry:option(ListValue, "baud", translate("Telemetry UART Baud Rate"))
o_telemetry_baud:value(9600, "9600 bps")
o_telemetry_baud:value(19200, "19200 bps")
o_telemetry_baud:value(38400, "38400 bps")
o_telemetry_baud:value(57600, "57600 bps")
o_telemetry_baud:value(115200, "115200 bps")
o_telemetry_baud:value(230400, "230400 bps")
o_telemetry_baud.default = 57600
o_telemetry_baud:depends("mode", "tx")
-- wbc.telemetry.cts: Telemetry TX CTS
o_telemetry_cts = s_telemetry:option(ListValue, "cts", translate("Telemetry TX CTS Mode"))
o_telemetry_cts:value(0, translate("CTS Protection Disabled"))
o_telemetry_cts:value(1, translate("CTS Protection Enabled"))
o_telemetry_cts.default = 0
o_telemetry_cts:depends("mode", "tx")
-- wbc.telemetry.retrans: Telemetry TX Retransmission Count
o_telemetry_retrans = s_telemetry:option(ListValue, "retrans", translate("Telemetry TX Retransmission Count"))
o_telemetry_retrans:value(1, translate("Send each frame once"))
o_telemetry_retrans:value(2, translate("Twice"))
o_telemetry_retrans:value(3, translate("Three times"))
o_telemetry_retrans.default = 2
o_telemetry_retrans:depends("mode", "tx")
-- wbc.telemetry.proto: Telemetry TX Protocol
o_telemetry_proto = s_telemetry:option(ListValue, "proto", translate("Telemetry Protocol"))
o_telemetry_proto:value(0, translate("Mavlink"))
o_telemetry_proto:value(1, translate("Generic"))
o_telemetry_proto.default = 0
o_telemetry_proto:depends("mode", "tx")
-- wbc.telemetry.send_ip_port: Telemetry RX Send to IP:Port	
o_telemetry_send_ip_port = s_telemetry:option(Value, "send_ip_port", translate("Send Telemetry Data to IP:Port"))
o_telemetry_send_ip_port.datatype = "ipaddrport"
o_telemetry_send_ip_port:depends("mode", "rx")
-- wbc.telemetry.save_enable: Telemetry Save Enable
o_telemetry_save_enable = s_telemetry:option(Flag, "save_enable", translate("Enable Telemetry Save"))
o_telemetry_save_enable.rmempty = false
o_telemetry_save_enable:depends("mode", "rx")
-- wbc.telemetry.savepath: Save Telemetry Data To Path
o_telemetry_savepath = s_telemetry:option(Value, "telemetry", translate("Save Telemetry Data To Path"))
o_telemetry_savepath.default = '/mnt/sda1/wbc_telemetry'
o_telemetry_savepath.placeholder = '/mnt/sda1/wbc_telemetry'
o_telemetry_savepath:depends("save_enable", 1)
-- wbc.telemetry.encrypt_enable: telemetry Encrypt Enable
o_telemetry_encrypt_enable = s_telemetry:option(Flag, "encrypt_enable", translate("Encrypt"))
o_telemetry_encrypt_enable.rmempty = false
o_telemetry_encrypt_enable:depends("enable", 1)
-- wbc.telemetry.password: Encrypt Password
o_telemetry_encrypt_password = s_telemetry:option(Value, "encrypt_password", translate("Password"))
o_telemetry_encrypt_password.rmempty = false
o_telemetry_encrypt_password.password = true
o_telemetry_encrypt_password:depends("encrypt_enable", 1)
-- wbc.telemetry.ratelevel: telemetry transmission rate level
o_telemetry_ratelevel = s_telemetry:option(ListValue, "ratelevel", translate("telemetry transmission rate level"))
o_telemetry_ratelevel.rmempty = false
o_telemetry_ratelevel:value("H", translate("High rate (Low power)"))
o_telemetry_ratelevel:value("L", translate("Low rate (High power)"))
o_telemetry_ratelevel.default = "L"
o_telemetry_ratelevel:depends("mode", "tx")




local apply = luci.http.formvalue("cbi.apply")
if apply then
	luci.sys.exec("/etc/init.d/ezwifibroadcast enable")
    luci.sys.exec("/etc/init.d/ezwifibroadcast restart")
end

return m


--[[

-- -- wbc.rc: R/C settings
-- s_rc = m:section(TypedSection, "rc", translate("R/C Settings"))
-- s_rc.anonymous = true
-- s_rc.addremove = false
-- -- wbc.rc.enable: R/C Enable
-- o_rc_enable = s_rc:option(Flag, "enable", translate("Enable R/C"))
-- o_rc_enable.rmempty = false
-- -- wbc.rc.mode: R/C Mode
-- -- depends on: wbc.rc.enable
-- o_rc_mode = s_rc:option(ListValue, "mode", translate("Mode"))
-- o_rc_mode.rmempty = false
-- o_rc_mode:value("tx", translate("Transceiver"))
-- o_rc_mode:value("rx", translate("Receiver"))
-- o_rc_mode.default = "tx"
-- o_rc_mode:depends("enable", 1)
-- -- wbc.rc.uart: R/C UART Interface
-- -- depends on: wbc.rc.enable
-- o_rc_uart = s_rc:option(ListValue, "uart", translate("R/C UART Interface"))
-- for k,v in ipairs(tty_list) do 
	-- o_rc_uart:value(v) 
-- end
-- o_rc_uart.default = "/dev/ttyUSB0"
-- o_rc_uart:depends("enable", 1)
-- -- wbc.rc.proto: R/C TX Protocol
-- -- depends on: wbc.rc.enable
-- o_rc_proto = s_rc:option(ListValue, "proto", translate("R/C Protocol"))
-- o_rc_proto:value("sbus", translate("S.BUS"))
-- o_rc_proto:value("raw", translate("Raw Data"))
-- o_rc_proto.default = 0
-- o_rc_proto:depends("enable", 1)
-- -- wbc.rc.encrypt_enable: R/C Encrypt Enable
-- o_rc_encrypt_enable = s_rc:option(Flag, "encrypt_enable", translate("Encrypt"))
-- o_rc_encrypt_enable.rmempty = false
-- o_rc_encrypt_enable:depends("enable", 1)
-- -- wbc.rc.password: Encrypt Password
-- o_rc_encrypt_password = s_rc:option(Value, "encrypt_password", translate("Password"))
-- o_rc_encrypt_password.rmempty = false
-- o_rc_encrypt_password.password = true
-- o_rc_encrypt_password:depends("encrypt_enable", 1)
-- -- wbc.rc.ratelevel: rc transmission rate level
-- o_rc_ratelevel = s_rc:option(ListValue, "ratelevel", translate("rc transmission rate level"))
-- o_rc_ratelevel.rmempty = false
-- o_rc_ratelevel:value("H", translate("High rate (Low power)"))
-- o_rc_ratelevel:value("L", translate("Low rate (High power)"))
-- o_rc_ratelevel.default = "L"
-- o_rc_ratelevel:depends("mode", "tx")

-- 4G won't come, and not now

-- wbc.rc.transmode: R/C Transfer Mode
-- depends on: wbc.rc.enable
o_rc_transmode = s_rc:option(ListValue, "transmode", translate("Transfer Mode"))
o_rc_transmode.rmempty = true
o_rc_transmode:value(0, translate("Send packet to air via Wi-Fi card"))
o_rc_transmode:value(1, translate("Send packet to UDP (For 4G LTE)"))
o_rc_transmode:value(2, translate("Send packet to both Wi-Fi & UDP"))
o_rc_transmode.default = 0
o_rc_transmode:depends("mode", "tx")
-- wbc.rc.recvmode: R/C Receive Mode
-- depends on: wbc.rc.enable
o_rc_recvmode = s_rc:option(ListValue, "recvmode", translate("Receive Mode"))
o_rc_recvmode.rmempty = true
o_rc_recvmode:value(0, translate("Get packet from Wi-Fi card"))
o_rc_recvmode:value(1, translate("Get packet from UDP (For 4G LTE)"))
o_rc_recvmode:value(2, translate("Get packet from both Wi-Fi & UDP"))
o_rc_recvmode.default = 0
o_rc_recvmode:depends("mode", "rx")
-- wbc.rc.udp_ip_port: R/C Data send to IP:Port (for tx udp mode)
-- wbc.rc.listen_port: get data from localhost:port (for rx udp mode)

]]
--[[
-- wbc.uplink: Uplink settings
s_uplink = m:section(TypedSection, "uplink", translate("Uplink Settings"))
s_uplink.anonymous = true
s_uplink.addremove = false
-- wbc.uplink.enable: Uplink Enable
o_uplink_enable = s_uplink:option(Flag, "enable", translate("Enable Uplink"))
o_uplink_enable.rmempty = false
-- wbc.uplink.mode: Uplink Transfer Mode
o_uplink_mode = s_uplink:option(ListValue, "mode", translate("Transfer Mode"))
o_uplink_mode.rmempty = false
o_uplink_mode:value("tx", translate("Transceiver"))
o_uplink_mode:value("rx", translate("Receiver"))
o_uplink_mode.default = "tx"
-- wbc.uplink.port: Uplink Port on Air
o_uplink_port = s_uplink:option(Value, "port", translate("Uplink Port on Air"))
o_uplink_port.default = 3
o_uplink_port.placeholder = 3
o_uplink_port.datatype = "range(0,127)"
-- wbc.uplink.cts: Uplink TX CTS
o_uplink_cts = s_uplink:option(ListValue, "cts", translate("Uplink TX CTS Mode"))
o_uplink_cts:value(0, translate("CTS Protection Disabled"))
o_uplink_cts:value(1, translate("CTS Protection Enabled"))
o_uplink_cts.default = 0
o_uplink_cts:depends("mode", "tx")
-- wbc.uplink.retrans: Uplink TX Retransmission Count
o_uplink_retrans = s_uplink:option(ListValue, "retrans", translate("Uplink TX Retransmission Count"))
o_uplink_retrans:value(1, translate("Send each frame once"))
o_uplink_retrans:value(2, translate("Twice"))
o_uplink_retrans:value(3, translate("Three times"))
o_uplink_retrans.default = 2
o_uplink_retrans:depends("mode", "tx")
-- wbc.uplink.bitrate: Uplink TX Bit Rate
o_uplink_bitrate = s_uplink:option(ListValue, "bitrate", translate("Uplink TX Bitrate"))
o_uplink_bitrate:value(6, "6 Mbps")
o_uplink_bitrate:value(12, "12 Mbps")
o_uplink_bitrate:value(18, "18 Mbps")
o_uplink_bitrate:value(24, "24 Mbps")
o_uplink_bitrate:value(36, "36 Mbps")
o_uplink_bitrate.default = 6
o_uplink_bitrate:depends("mode", "tx")
-- wbc.uplink.uart: Uplink UART Interface
o_uplink_uart = s_uplink:option(ListValue, "uart", translate("Uplink UART Interface"))
for k,v in ipairs(tty_list) do 
	o_uplink_uart:value(v) 
end
o_uplink_uart.default = "/dev/ttyUSB0"
-- wbc.uplink.baud: Uplink UART Baud rate
o_uplink_baud = s_uplink:option(ListValue, "baud", translate("Uplink UART Baud Rate"))
o_uplink_baud:value(9600, "9600 bps")
o_uplink_baud:value(19200, "19200 bps")
o_uplink_baud:value(38400, "38400 bps")
o_uplink_baud:value(57600, "57600 bps")
o_uplink_baud:value(115200, "115200 bps")
o_uplink_baud:value(230400, "230400 bps")
o_uplink_baud.default = 57600
o_uplink_baud:depends("mode", "rx")
-- wbc.uplink.proto: Uplink TX Protocol
o_uplink_proto = s_uplink:option(ListValue, "proto", translate("Uplink Protocol"))
o_uplink_proto:value(0, translate("Mavlink"))
o_uplink_proto:value(1, translate("Generic"))
o_uplink_proto.default = 0
o_uplink_proto:depends("mode", "tx")
-- wbc.uplink.rproto: Uplink RX Protocol
o_uplink_rproto = s_uplink:option(ListValue, "rproto", translate("Uplink RX Protocol"))
o_uplink_rproto:value(0, translate("MSP"))
o_uplink_rproto:value(1, translate("Mavlink"))
o_uplink_rproto:value(2, translate("SUMD"))
o_uplink_rproto:value(3, translate("IBUS"))
o_uplink_rproto:value(4, translate("SRXL/XBUS"))
o_uplink_rproto:value(99, translate("disable R/C"))
o_uplink_rproto.default = 0
o_uplink_rproto:depends("mode", "rx")
]]
