# coding: UTF-8
Encoding.default_external = 'UTF-8'

time_start = Time.now

require 'yaml'
require "tk"
require "win32ole"

module TC #; TC.set( __FILE__ , __LINE__  )  ;TC.setget( __FILE__ , __LINE__  );
	@list = Hash.new
	@step = []
	@pre_t = Time.now
	def self.kg(f,l)
		f + ":" + l.to_s
	end
	def self.set(f,l,come=nil)
		sa = Time.now - @pre_t
		key = kg(f,l)
		@step << [key , sa]
		if @list.has_key?(key)
			@list[key][0] += sa 
			@list[key][1] += 1 
		else
			@list[key]=[ sa , 1 , come]
		end
		@pre_t = Time.now
	end
	def self.setget(f,l,come=nil)
		set(f,l,come)
		# [ f,l ,@list[kg(f,l)]  ]
		sprintf("%d , %f \n" , l ,@list[kg(f,l)][0]  )
	end
	def self.stepmax
		@step.sort{|a,b|
				a[1]<=>b[1]
			}.each{|h|
					printf("%s %.9f\n", h[0] , h[1])
				}
	end
	def self.allsum
		@list.sort{|a,b|
				a[1][0]<=>b[1][0]
			}.each{|h|
					printf("%s %.9f %d\n", h[0] , h[1][0] , h[1][1])
				}
	end
	def self.allave
		@list.sort{|a,b|
				(a[1][0]/a[1][1])<=>(b[1][0]/b[1][1])
			}.each{|h|
					printf("%s %.9f %d\n", h[0] , h[1][0] , h[1][1])
				}
	end
end


require 'tracer'
Tracer.off
class Tracer
	alias org_trace_func  trace_func
	def trace_func(event, file, line, id, binding, klass, *) # :nodoc:
		return if !file.include?(__FILE__)
		#TC.set( file , line  );
		org_trace_func(event, file, line, id, binding, klass)
	end
end
Tracer.off
#Tracer.on


class Kline
	Lasttime = 'lasttime'
	Oldtime = 'oldtime'
	Newtime = 'newtime'
	StrTime = "%y/%m/%d %R"
	Yes = 'yes'
	No = 'no'
	ORG = [ 0 , 0 , 0 , Yes , ( Time.now.to_i - (60*60*24*365) ) ]
	# new Kline(path,argv)
	# "パス" [ 合計時間 最長時間 実行回数 on/off last filesize oldtime newtime Weight ]
	def initialize( path , allnum = [] )
		nn = 0
		ORG.each{|it|
			if ( allnum.size-1 < nn )
				allnum << it 
			end
			nn += 1
		}
		@path = path ; num = 0
		@all_time = allnum[num].to_i ; num += 1 
		@max_time = allnum[num].to_i ; num += 1 
		@exec_num = allnum[num].to_i ; num += 1 
		@sw = allnum[num] ; num += 1 
		@lasttime = allnum[num].to_i ; num += 1 
		if allnum.size < 6 && File.exist?( @path )
			#p "timeget"
			#@fsize =  File.size( @path )
			time_stat_set()
			num += 3
		else
			@fsize =  allnum[num].to_i ; num += 1 
			@oldtime = allnum[num].to_i ; num += 1 
			@newtime = allnum[num].to_i ; num += 1 
		end
		if allnum.size < 9
			@sort_weight = 5 ; num += 1 
		else
			@sort_weight = allnum[num].to_i ; num += 1 
		end
	end
	def exist?()
		File.exist?( @path )
	end
	def time_stat_set()
		time_stat = File::Stat.new(@path)
		tl = [ time_stat.birthtime.to_i \
				,time_stat.mtime.to_i \
				,time_stat.ctime.to_i \
				,time_stat.atime.to_i ]
		# ファイル作成日時 最終更新日時 最終状態変更日時 最終アクセス日時
		tl.sort!
		@fsize =  File.size( @path )
		@oldtime = time_stat.birthtime.to_i # 作成日
		@newtime = time_stat.mtime.to_i # 更新日
	end
	def setpath(aa) @path = aa ; end 
	def path() @path ; end 
	def all_time() @all_time==0 ? 0.99 : @all_time ; end 
	def exec_num() @exec_num==0 ? 0.99 : @exec_num + 0.99; end 
	def max_time() @max_time==0 ? 0.99 : @max_time ; end 
	def lasttime() @lasttime ; end
	def fsize() @fsize ; end
	def oldtime() @oldtime ; end
	def newtime() @newtime ; end
	def sort_weight_io(weigthin=nil)
		if weigthin == nil
			@sort_weight = 5 if !( @sort_weight.is_a?(Numeric) )
		else
			@sort_weight = weigthin
		end
		@sort_weight = 5 if !( @sort_weight.is_a?(Numeric) )
		@sort_weight = 9 if @sort_weight > 9
		@sort_weight = 1  if @sort_weight < 1
		@sort_weight
	end
	def relasttime(zerolast=60*60*24*365)
		if @exec_num==0
			@lasttime = ( Time.now.to_i + (zerolast) )
		end
	end
	def sw(s=nil)
		if s==nil
			@sw
		elsif s==Yes || s==No
			@sw = s
		else
			@sw = Yes
		end
	end
	def timeview(timeword)
		case timeword
		when Lasttime
			Time.at(@lasttime).strftime(StrTime)
		when Oldtime
			Time.at(@oldtime).strftime(StrTime)
		when Newtime
			Time.at(@newtime).strftime(StrTime)
		end
	end
	def add_time(i)
		if !i.is_a?(Numeric)
			p i
		else
			i = i.round
			@max_time = i if @max_time < i
			@exec_num += 1
			@lasttime = Time.now.to_i
			@all_time += i
		end
	end
	def lineoutpout
		# 1行の書式 "パス" 合計時間 最長時間 実行回数 on/off last 
		sprintf("\"%s\" %d %d %d %s %d %d %d %d %d \n",@path,@all_time,@max_time,@exec_num,@sw,@lasttime,@fsize,@oldtime,@newtime, sort_weight_io() )
	end
end # class Kline


$startupdir = "./" # Dir.chdir( $startupdir ) 
module DB

	J_LAST_EXEC = '最終実行日'
	J_EXEC_NUM = '実行数'
	J_AVE_EXEC = '平均時間'
	J_MAX_EXEC = '最長時間'
	J_SUM_EXEC = '合計時間'
	J_OldTime = 'FILE作成日'
	J_NewTime = 'FILE更新日'
	J_FILESIZE = 'FILEサイズ'
	J_WORDFIND = 'ワード検索'
	J_PRESORT = '直前のソート'
	J_WEIGHT = 'w(重み)' # sort_weight

	LIST_FILE = "listapp_list.txt"
	BINFILE = "listapp_list.bin"
	INI_FILE = "listapp_setting.yml"
	
	ExtStr = Struct.new( :name, :ext, :path)
	FindSet= Struct.new( :name, :path,:ext,:incword,:noword )
	SubFind = Struct.new( :key, :value, :weight)
	
	EXT_WORD = "拡張子別実行プログラム"
	FIND_WORD = "検索設定"
	SUB_SORT_SET = "自動ソート設定"

	RAND_EXEC_1 = "表示中から\nランダム実行する"
	RAND_EXEC_2 = "ランダム実行中\n...中断する.."
	RAND_EXEC_3 = "実行中のものの\n...終了待ち.."
	
	IRO_AKA = "#FF0000"
	IRO_KI  = "#FFFF00"
	
	SUB_fillwin = "sub_fillwin"
	SUB_fillwin1 = "sub_fillwin1"
	SUB_fillwin2 = "sub_fillwin2"
	SUB_set_ext = "sub_set_ext"
	SUB_set_find = "sub_set_find"	
	Set_Main_Win_Ini = "set_main_win_ini"
	MAIN_LIST_VIEW_NUM = 'MAIN_LIST_VIEW_NUM'
	NOT_EXEC_FIND_EXECTIME = 'NOT_EXEC_FIND_EXECTIME'
	
	RANDAM_EXEC_NUM = 'RANDAM_EXEC_NUM'
	
	## TEST DATA START
	Def_ini_data = Hash.new
	Def_ini_data[EXT_WORD] = [ \
		ExtStr.new( "動画sumple" , "avi|mpg|mp4|mov|mkv|wmv" , "C:/Program Files (x86)/Windows Media Player/wmplayer.exe" ) , \
		ExtStr.new( "画像sumple" , "zip|lzh" , "D:/HONEYVIEW-PORTABLE/Honeyview32.exe"  ) , \
		ExtStr.new( "実行sumple" , "exe|pdf" , "system() # 直接実行、もしくは関連付けのプログラムで実行"  ) , \
		ExtStr.new("no4","",""),ExtStr.new("no5","",""),ExtStr.new("no6","",""), \
	]
	Def_ini_data[FIND_WORD] = [ \
		FindSet.new( "1sumple" , "E:/コミック" , "zip|pdf" , "同人|成年|一般|雑誌" , "ゲーム" ) , \
		FindSet.new( "2sumple" , "E:/ゲーム" , "exe" , "同人|18禁" , "setting|unins|診断|setup|install|conf|alpharom|check|savefolder|menu|インストール|セーブ|チェック|設定" ) , \
		FindSet.new( "3sumple" , "E:/動画" , "avi|mpg|mp4|mov|mkv|wmv" , "/アニメ/|/AV/" , "ゲーム" ) , \
	]
	4.upto(10){|nn| Def_ini_data[FIND_WORD] << FindSet.new("#{nn}","","","","") }
	Def_ini_data[SUB_SORT_SET]= [ # DB.ini_data[DB::SUB_SORT_SET]
		SubFind.new(J_PRESORT,0,500),
		SubFind.new(J_WORDFIND,0,200),
		SubFind.new(J_WEIGHT,1,150), # sort_weight
		SubFind.new(J_LAST_EXEC,-1,100),
		SubFind.new(J_AVE_EXEC,1,75),
		SubFind.new(J_OldTime,1,50),
		SubFind.new(J_EXEC_NUM,1,8),
		SubFind.new(J_SUM_EXEC,1,6),
		SubFind.new(J_MAX_EXEC,1,5),
		SubFind.new(J_NewTime,1,0),
	]
		#SubFind.new(J_FILESIZE,1,7), ファイルサイズソート
	Def_ini_data[NOT_EXEC_FIND_EXECTIME] = -365 
	Def_ini_data[MAIN_LIST_VIEW_NUM] = 20 
	Def_ini_data[RANDAM_EXEC_NUM] = 3
	## TEST DATA END
	
	No_Auto_Save = [ EXT_WORD , FIND_WORD , SUB_SORT_SET , MAIN_LIST_VIEW_NUM , NOT_EXEC_FIND_EXECTIME ]
	@nowlist = []
	@listhozon = 0
	@ini_data = nil
	@each_job = nil
	
	##-- 実行スレッド用
	@prrclicktime = Time.now
	@killbutton = false
	
	class << self
		attr_accessor :nowlist
		attr_accessor :ini_data
		attr_accessor :each_job
		
		def not_exec_find_exectime(num = nil)
			if num == nil
				@ini_data[NOT_EXEC_FIND_EXECTIME] == nil ? -365 : @ini_data[NOT_EXEC_FIND_EXECTIME]
			else
				@ini_data[NOT_EXEC_FIND_EXECTIME] = num
			end
		end
		def main_list_view_num(num = nil)
			if num == nil
				@ini_data[MAIN_LIST_VIEW_NUM] == nil ? 20 : @ini_data[MAIN_LIST_VIEW_NUM]
			else
				@ini_data[MAIN_LIST_VIEW_NUM] = num
			end
		end
		def rundam_exec_num(num = nil)
			if num == nil
				@ini_data[RANDAM_EXEC_NUM] == nil ? 5 : @ini_data[RANDAM_EXEC_NUM]
			else
				@ini_data[RANDAM_EXEC_NUM] = num
			end
		end
		
		##-- 初期読み込み
		def new()
			list_read()
			start_read()
		end
		
		##-- yaml 書き込み　とりまとめ
		def yaml_write(file,data)
			Dir.chdir( $startupdir )
			open( file , "w"){ |f| f.write(YAML.dump(data)) }
		end
		##-- yaml 読み込み　とりまとめ
		def yaml_read(file)
			Dir.chdir( $startupdir )
			YAML.load_file( file )
		end

		##-- 起動時用設定データの読み込み
		def start_read
			Dir.chdir( $startupdir )
			@ini_data = nil
			if !File.exist?( INI_FILE)
				if @ini_data == nil
					@ini_data = Def_ini_data
				end
				yaml_write(INI_FILE,@ini_data)
			else
				@ini_data = yaml_read(INI_FILE)
				if !@ini_data.has_key?(SUB_SORT_SET)
					@ini_data[SUB_SORT_SET] = Def_ini_data[SUB_SORT_SET]
				elsif @ini_data[SUB_SORT_SET].size != Def_ini_data[SUB_SORT_SET].size
					@ini_data[SUB_SORT_SET] = Def_ini_data[SUB_SORT_SET]
				end
			end
		end

		##-- 設定保存確認
		def ini_save_kakunin(baseseet)
			subformtop = TkToplevel.new(baseseet){
				geometry "+#{TkWinfo.rootx($root)+10}+#{TkWinfo.rooty($root)+10}"
				}.withdraw

			subformtop.title("設定保存確認")
			la = TkLabel.new(subformtop,text:"設定に変更がありますどうしますか？").pack(padx:3,pady:3,side:'top',fill:'both')
			applay = TkButton.new(subformtop,text:'上書き保存',width:15,borderwidth:3).pack(padx:3,pady:3,side:'left',fill:'both')
			revase = TkButton.new(subformtop,text:'変更前に戻す',width:15,borderwidth:3).pack(padx:3,pady:3,side:'left',fill:'both')
			cancel = TkButton.new(subformtop,text:'何もせずスキップ',width:15,borderwidth:3).pack(padx:3,pady:3,side:'left',fill:'both')
			last_value = "skip"
			applay.command( proc{ last_value = "save" ; subformtop.destroy() } )
			revase.command( proc{ last_value = "load" ; subformtop.destroy() } )
			cancel.command( proc{ last_value = "skip" ; subformtop.destroy() } )
			# windowの右上　xボタンが押されたとき設定
			subformtop.wm_protocol('WM_DELETE_WINDOW',proc{ last_value = "skip" ; subformtop.destroy() } )
			#- wait
			subformtop.deiconify()
			la.focus
			subformtop.set_grab
			subformtop.wait_destroy()
			subformtop.release_grab
			return(last_value)
		end

		##-- 設定データの読み込み 設定データの保存 共通
		def setini_read_and_wite()
			result = ""
			if !setini_diff()
				result = ini_save_kakunin($root)
				case result
				when "save"
					@ini_data["window"] = nowwindow
					yaml_write(INI_FILE,@ini_data)
				when "load"
					@ini_data = yaml_read(INI_FILE)
				else # "skip"
					return "skip"
				end
			end
			result
		end
		
		# 編集を検出したらfalse
		def setini_diff()
			Dir.chdir( $startupdir )
			old_data = nil
			if File.exist?( INI_FILE)
				old_data = yaml_read(INI_FILE)
			end
			swflag = true
			No_Auto_Save.each{|dbw|
				if @ini_data[dbw].nil? != old_data[dbw].nil?
					swflag = false
					break
				end
				if @ini_data[dbw].size != old_data[dbw].size
					swflag = false
					break
				end
				if @ini_data[dbw].class == [].class
					@ini_data[dbw].each_index{|idx|
						if @ini_data[dbw][idx].to_a.join(",") != old_data[dbw][idx].to_a.join(",")
							swflag = false
							break
						end
					}
				else
						if @ini_data[dbw]!= old_data[dbw]
							swflag = false
							break
						end
				end
			}
			swflag
		end
				
		##-- 設定データ　自動セーブカテゴリ
		def set_main_win_ini(key,val)
			if !@ini_data.has_key?(Set_Main_Win_Ini)
				@ini_data[Set_Main_Win_Ini] = Hash.new
			end
			@ini_data[Set_Main_Win_Ini][key] = val
		end
		def get_main_win_ini(key)
			if !@ini_data.has_key?(Set_Main_Win_Ini)
				@ini_data[Set_Main_Win_Ini] = Hash.new
			end
			@ini_data[Set_Main_Win_Ini].has_key?(key) ? @ini_data[Set_Main_Win_Ini][key] : nil
		end
		def savesubwin(key,toplevel)
			@ini_data[key] = TkWinfo.geometry(toplevel)
			setini_winonly_wite()
		end
		def loadsubwin(key)
			if @ini_data.has_key?(key)
				@ini_data[key]
			else
				nil
			end
		end
		def savesubword(key,wordlist = [])
			@ini_data[key+"word"] = wordlist
			setini_winonly_wite()
		end
		def loadsubword(key)
			if @ini_data.has_key?(key+"word")
				@ini_data[key+"word"]
			else
				nil
			end
		end
		def nowwindow()
			wh = {
				:geometry => TkWinfo.geometry($root) ,
				:xx => TkWinfo.x($root) ,
				:yy => TkWinfo.y($root),
				:rootx => TkWinfo.rootx($root),
				:rooty => TkWinfo.rooty($root),
				:height => TkWinfo.height($root),
				:width => TkWinfo.width($root),
				:screenheight => TkWinfo.screenheight($root),
				:screenwidth => TkWinfo.screenwidth( $root ),
				:path_width_offset => Seet1.path_width_offset
			}
		end
		def setini_winonly_wite() # 自動セーブカテゴリのみ保存
			oldini = yaml_read(INI_FILE)
			nowdata = Marshal.load( Marshal.dump( @ini_data.clone ) )
			No_Auto_Save.each{|ww|
				nowdata[ww]  = oldini[ww]
			}
			nowdata["window"] = nowwindow
			yaml_write(INI_FILE,nowdata)
		end
		
		##-- リスト保存
		def list_remake()
			Dir.chdir( $startupdir )
			Seet1.weight_save() # koko 重み保存
			logging( "listsize" , @nowlist.size )
			list_file_w = LIST_FILE.clone
			tempname = "._pre_." + list_file_w
			filemake = proc{|filename|
				File.open( filename , "w" ){ |ff|
					@nowlist.each{|ll|
						ff.printf("%s" , ll.lineoutpout ) # リストファイルに追記
					}
				}
			}
			# テキスト一時保存
			s1 = Time.now
			filemake.call(tempname)
			logging [ "テキスト形式保存" , Time.now - s1 ]
			filemake.call(list_file_w) if !File.exist?(list_file_w)
			if File.size( list_file_w ) > File.size( tempname  )
			#if File.size( list_file_w ) != File.size( tempname  )
				## koko
				## 新規のデータが旧データよりサイズが小さいとき旧データのバックアップを取る
				day = Time.now
				timename = sprintf("%d%02d%02d%02d%02d%02d",day.year,day.month,day.day,day.hour,day.min,day.sec)
				File.rename( list_file_w, list_file_w + timename ) # 古いデータをバックアップ
			else
				File.rename(list_file_w,list_file_w+"_bkup.txt")
			end
			# テキスト本保存
			File.rename( tempname, list_file_w)
			
			# バイナリ保存
			s1 = Time.now
			File.open( BINFILE , "wb" ){ |ff|
				ff.write(  Marshal.dump(@nowlist))
			}
			logging [ "バイナリ形式保存" , Time.now - s1 ]
		end
		
		##-- リスト読み込み
		def list_read()
			Dir.chdir( $startupdir )
			@nowlist.clear
			#-- テキスト読み込み
			if !File.exist?(BINFILE) && File.exist?(LIST_FILE)
				s1 = Time.now
				non_file_sw = false
				File.open( LIST_FILE , "r" ){ |ff|
					ff.read.split("\n").each{ |line1|
					# 1行の書式 "パス" 合計時間 最長時間 実行回数 on/off last 
						aa = line1.split("\"") # ファイルは"ダブルクォーテーション区切り
						@nowlist << Kline.new( aa[1] , aa[2].split(" ") )
					}
				}
				logging [ "Text形式読み込み" , Time.now - s1 ]
			end
			#--　バイナリ読み込み
			if File.exist?(BINFILE)
				s1 = Time.now
				File.open( BINFILE , "rb" ){ |ff|
					@nowlist = Marshal.load( ff.read(  ) )
				}
				logging [ "Bin形式読み込み" , Time.now - s1 ]
			end
		end # def list_read()

		## プロセスゲット
		def getnowpro()
			process_list = WIN32OLE.connect("winmgmts:").InstancesOf("Win32_process")
			allp = []
			process_list.each{ |process|
				allp << [process.Name,process.ExecutablePath]
			}
			allp
		end
		##-- プロセス監視
		def syswite(prog)
			begin
				while true
					sleep 1
					allp = getnowpro()
					break if !allp.flatten.include?( prog )
				end
			rescue=>e
				logging [ "syswite エラー" , e ]
			end
		end
		
		##-- エクスプローラー
		def open_exp(path)
			enpath = path.gsub("/","\\")
			system("explorer.exe \/select,\"#{enpath}\"")
		end
		
		##-- 実行スレッド
		def exec(gyou,renzokubotton=nil)
			return if 2 > Time.now - @prrclicktime # 連続クリック禁止 
			@prrclicktime = Time.now
			if gyou.class != [nil].class
				if Seet1::NumButton_OPEN == Seet1.numbutton_open
					open_exp(@nowlist[gyou].path)
					return
				end
				gyou = [gyou]
			end
			begin
				@killbutton = false
				
				if ( @each_job == nil \
						|| ( (@each_job != nil) && !@each_job.alive? ) )
						
					each_Array = gyou.clone
					
					@each_job = Thread.new do
						bktext = renzokubotton.text.clone
						bkbkcl = renzokubotton.background.clone
						bkfocl = renzokubotton.foreground.clone
						if bktext.include?(DB::RAND_EXEC_1)
							renzokubotton.text = DB::RAND_EXEC_2
						else
							renzokubotton.text = "実行中"
						end
						renzokubotton.background = DB::IRO_AKA
						renzokubotton.foreground = DB::IRO_KI
						renzokubotton.update
						each_Array.each{|bnum|
							exec_sub(bnum)
							@listhozon += 1
							break if  @killbutton
						}
						list_remake() if @listhozon % 5 == 0 # koko
						renzokubotton.text = bktext
						renzokubotton.background = bkbkcl
						renzokubotton.foreground = bkfocl
						renzokubotton.update
						self.kill
					end
					
				else # KILL
					if renzokubotton.text.include?(DB::RAND_EXEC_2)
						renzokubotton.background = DB::IRO_KI
						renzokubotton.foreground = DB::IRO_AKA
						renzokubotton.text = DB::RAND_EXEC_3
						renzokubotton.update
					end
					@killbutton = true
				end
			rescue => e
				 p e.class
				 p e.message
				 p e.backtrace
			end
			gyou.clear
		end
		
		#- 実際の実行　拡張子別判定
		def exec_sub(gyou)
			kicknow = @nowlist[gyou]
			#---
			if !File.exist?(kicknow.path)
				return
			end
			#---
			if kicknow.sw =='no'
				open_exp(kicknow.path)
				return
			end
			#---
			execck = Regexp.compile( "(exe)$" , Regexp::IGNORECASE)
			if kicknow.exec_num < 1 && ( kicknow.path.match(execck) != nil )
				st = check_exec($root,kicknow)
				return if st == 'skip'
			end
			#---
			@ini_data[EXT_WORD].select{|aa|
				aa[:path].size > 2 &&  aa[:ext].size > 1
			}.each{|path_kaku| # :name, :ext, :path)
				extreg = Regexp.compile( "("+path_kaku[:ext]+")$"  , Regexp::IGNORECASE)
				if kicknow.path.match(extreg)
					execpath = path_kaku[:path]
					execpath = "" if path_kaku[:path].include?("system() #")
					starttimt = Time.now # 計測中
					if execpath == ""
						s1 = Time.now
							strstart = " call "
							strstart = " " if kicknow.path.match(execck) != nil
							commanstr = "#{strstart}\"#{File.basename(kicknow.path)}\""
							oldpro = getnowpro()
								
								Dir.chdir( File.dirname( kicknow.path ) ) do
									system( commanstr )
								end
							
							logging commanstr
						s2 = Time.now - s1
						if s2 < 10
							sleep 1
							nowpro = getnowpro()
							nowpro.delete_if{|obj| oldpro.include?(obj) }
							checkpath = File.basename( kicknow.path )
							checkpath = nowpro[0][0] if nowpro.size == 1
				logging [ "checkpath" , checkpath ]
							syswite(checkpath)
						end
					else
						system("\"#{execpath}\" \"#{kicknow.path}\"")
					end
					korejikan = Time.now - starttimt
					kicknow.add_time(korejikan)
					Seet1.review()
					logging [ kicknow.path , korejikan ]
					break
				end # if kicknow.path.match(extreg)
			} # each
			
		end # def exec_sub(gyou)
		
		##-- 起動確認
		def check_exec(baseseet,pathset)
			subformtop = TkToplevel.new(baseseet){
				geometry "+#{TkWinfo.rootx($root)+10}+#{TkWinfo.rooty($root)+10}"
				}

			enpath = pathset.path
			subformtop.title("実行ファイルの起動確認")

			ypos = 1
			la = TkLabel.new(subformtop,
				text:" 初めての実行です。\n \"#{enpath}\" \nを起動しますか？").grid(ipadx:2,ipady:2,padx:2,pady:2 , row:ypos, column:1 , columnspan:100  ,sticky:'news')
			
			ypos = 2
			applay = TkButton.new(subformtop,
				text:'実行する（次回以降確認はしない）',
				borderwidth:3).grid(ipadx:2,ipady:2,padx:2,pady:2 ,row:ypos, column:1 ,sticky:'news')
			musi = TkButton.new(subformtop,
				text:'実行しない（有効チェックをはずして以降無視）',
				borderwidth:3).grid(ipadx:2,ipady:2,padx:2,pady:2 ,row:ypos, column:2 ,sticky:'news')
				
			ypos = 3
			exopen = TkButton.new(subformtop,
				text:'ファイルの場所を確認する',
				borderwidth:3).grid(ipadx:2,ipady:2,padx:2,pady:2 ,row:ypos, column:1 ,sticky:'news')
			cancel = TkButton.new(subformtop,
				text:'何もせずスキップ',
				borderwidth:3).grid(ipadx:2,ipady:2,padx:2,pady:2 ,row:ypos, column:2 ,sticky:'news')

			last_value = "skip"

			exopen.command( proc{ 
				open_exp(pathset.path)
			} )

			applay.command( proc{ last_value = "applay" ; subformtop.destroy() } )
			  musi.command( proc{ last_value = "skip" ;pathset.sw('no'); subformtop.destroy() } )
			cancel.command( proc{ last_value = "skip" ; subformtop.destroy() } )
			# windowの右上　xボタンが押されたとき設定
			subformtop.wm_protocol('WM_DELETE_WINDOW',proc{ last_value = "skip" ; subformtop.destroy() } )
			#- wait
			subformtop.deiconify()
			la.focus
			subformtop.set_grab
			subformtop.wait_destroy()
			subformtop.release_grab
			return(last_value)
		end
			
		def frame_update(tkval,text)## ステータスバー
			tkval.text text
			tkval.update
		end
		##-- ファイルの検索、チェック
		def findcheck( tkval = Frame.new(''))
			Dir.chdir( $startupdir )
			dellist = []

			#listのファイルの有無チェック	
			frame_update( tkval , "ファイルの有無確認" )
			@nowlist.delete_if{|fc|
				ret = false
				if !File.exist?(fc.path)
					frame_update( tkval , "削除検出" + fc.path ) ## ステータスバー
					logging [ "削除検出" , fc ]
					dellist << fc
					ret = true
				else
					fc.time_stat_set() # パスが存在するなら　サイズ、日付を更新
				end
				ret
			}
			
			#delファイル
			delfilebk = LIST_FILE + "_DEL_bkup.txt" 
			if File.exist?( delfilebk )
				File.open( delfilebk , "r" ){ |ff|
					ff.read.split("\n").each{ |line1|
						aa = line1.split("\"")
						dellist << Kline.new( aa[1] , aa[2].split(" ") )
					}
				}
			end

			#リストにない新しいファイルチェック
			reg_delword =  Regexp.compile( "()（）[]［］｢｣「」　_＿～~-―!！+＋".split("").map{|es| Regexp.escape(es)}.join("|")+ "|%|％|file(s)?" , Regexp::IGNORECASE)
			pre_eval_inc = " increg "
			pre_eval_not = " !notreg "
			aft_eval_inc = "increg.match(pathstr)"
			aft_eval_not = "!notreg.match(pathstr)" 
			newlist = []
			movelist = []
			
			name_check_proc = proc{|pckpath|
					# name_check_proc.call( newaddchack.path )
					nameck = pckpath.gsub("."," ").split("/")
					fname = ""
					if nameck.size == 2
						fname = nameck[1]
					elsif nameck.size == 3
						fname = nameck[1..2]
					elsif nameck.size > 3
						fname = nameck[-3..-1]
					end
					ckwords = fname.join(" ").gsub(reg_delword," ").gsub(/ +/," ").split(" ")
			}

			@ini_data[FIND_WORD].select{|aa|
				aa[:path].size > 2 &&  aa[:ext].size > 1
			}.each{|path_kaku| # 各検索条件の検索実施　:name, :path,:ext,:incword,:noword
				adir = path_kaku[:path]
				kakutyousi = path_kaku[:ext].gsub('|',',')
				increg = true
				notreg = false
				evalstr1 = pre_eval_inc
				evalstr2 = pre_eval_not
				if path_kaku[:noword].size > 2
					notreg = Regexp.compile( pipe_esc( path_kaku[:noword] ) , Regexp::IGNORECASE)
					evalstr2 = aft_eval_not
				end
				if path_kaku[:incword].size > 2
					increg = Regexp.compile( pipe_esc( path_kaku[:incword] ) , Regexp::IGNORECASE)
					evalstr1 = aft_eval_inc
				end

				frame_update( tkval , "検索中" + "#{adir}/**/*.{#{kakutyousi}}" ) ## TkVariable
				Dir.glob("#{adir}/**/*.{#{kakutyousi}}"){ |item|
				# dir検索開始
					pathstr = item.chomp.gsub("//","/")
					
					if eval( evalstr1 + "&&" + evalstr2 )
					# 検索条件にマッチするか？
					
						if (@nowlist+movelist+newlist).find{|fc| fc.path.chomp.gsub("//","/") == pathstr } == nil
						# 新規のファイルであるか？

							# oldtime 作成日 newtime 更新日
							# コピーされたファイルは　newtime < oldtime となる
							# 編集されたファイルは　newtime > oldtime となる
							newaddchack =  Kline.new( pathstr )
							mat_fsize_ok = dellist.select{|ob|
								ob.fsize == newaddchack.fsize
								}
							to_file = nil
							
							# ファイルサイズ判定
							if mat_fsize_ok.size > 1
							
								# 作成日、更新日が一致
								mats = mat_fsize_ok.select{|ob|
									ob.newtime == newaddchack.newtime && ob.oldtime == newaddchack.oldtime
								}
								if mats.size == 0
									mats = mat_fsize_ok.select{|ob|
										ob.newtime == newaddchack.newtime || ob.oldtime == newaddchack.oldtime
									}
								end
								
								if mats.size == 1
									to_file = mats[0] 
								else
									# 名前判定
									ckwords = name_check_proc.call( newaddchack.path )
									to_file = mats.max_by{|aa|
										con = 0
										ckwords.each{|bb| con += aa.path.count(bb) }
										con 
									}
								end
								
							elsif mat_fsize_ok.size == 1
							
								to_file = mat_fsize_ok[0]
								
							elsif mat_fsize_ok.size == 0
								# 一致するサイズがない(編集?)
								#matfind1 = dellist.select{|ob|
								#	ob.newtime < newaddchack.newtime && ob.oldtime == newaddchack.oldtime # 作成日が同じかつ更新日が新しい
								#}
							end
							
							#  新規か移動か
							if to_file == nil 
								logging [ "新規検出" , newaddchack ]
								frame_update( tkval , "新規追加" + pathstr ) ## ステータスバー
								newlist << newaddchack
							else
								dellist.delete_if{|ob| ob == to_file }
								logging [ "移動検出" , to_file.path ,  pathstr ]
								frame_update( tkval , "移動検出" + pathstr ) ## ステータスバー
								to_file.setpath(pathstr)
								movelist << to_file # メモリに追加
							end
						
						else
						
							# リストにあるファイル
						
						end # if 新しいファイルか？
						
					end # if 検索条件にマッチするか？
					
				} # dir.glob　検索ブロックの終了
				
			} # @ini_data[FIND_WORD].select{}.each{|path_kaku|　各検索条件の検索実施
			
			# リストデータの更新
			@nowlist += ( movelist + newlist )
			@nowlist.uniq!{|obj| obj.path } # 重複除去
			# offset_exec_time = @ini_data[NOT_EXEC_FIND_EXECTIME]*24*60*60
			offset_exec_time = not_exec_find_exectime() *24*60*60
			@nowlist.each{|tobj| tobj.relasttime( offset_exec_time ) } # 未実行の最終実行日時は一年前に統一
			
			#-削除されたデータの足しこみ
			@nowlist.each{|now_list_obj|
				check1 = dellist.select{|delobj|
					# 編集されていない？
					moveonly = now_list_obj.fsize == delobj.fsize \
					        && now_list_obj.newtime == delobj.newtime
					# 編集された
					#editfile = now_list_obj.fsize < delobj.fsize * 1.05 \
					#        && now_list_obj.newtime >  delobj.newtime
					editfile = false
					moveonly || editfile
				}
				
				if check1.size > 0
					check2 = check1.max_by{|delobj|
						# 削除データのパスを分解
						ckwords = name_check_proc.call( delobj.path )
						con = 0
						ckwords.each{|bb| con += now_list_obj.path.count(bb) }
						con
					}
					logging( "check_del" )
					logging( "nowlist" , now_list_obj )
					logging( "check2" ,  check2 )
					#logging( "con" , con )
				end
			}
			
			# 5文字削除
			#@nowlist.delete_if{|fc|
			#		if File.basename( fc.path ).size <= "a.zip".size
			#			# dellist << fc
			#			ret = true
			#		end
			#}
			
			#-
			list_remake() # リストファイルの更新
			
			logging( "kokopre" )
			logging( "@nowlist" , @nowlist.size )
			logging( "movelist x" , movelist.size )
			logging( "dellist" , dellist.size )
			logging( "newlist x" , newlist.size )

			# 削除されたファイルのデータを退避
			File.open( delfilebk , "w" ){ |ff|
				dellist.each{|ll|
					ff.printf("%s" , ll.lineoutpout ) # リストファイルに追記
				}
			}
			
			frame_update( tkval , "検索終了" ) ## ステータスバー
		end # def findcheck

		def pipe_esc(listword)
			listword.split("|").map{|es| 
				Regexp.escape(es.gsub("/",""))
			}.join("|") # .gsub("\/",".*\/.*").gsub("/.*|.*/","/|/").gsub("(.*/","(/").gsub("/.*)","/)")
		end

		def my_esc(onceword) # MY_ESCAPE
			onceword[0..-1].gsub(/\[/,"\\[").gsub(/\]/,"\\]").gsub(/\-/,"\\-")
		end
		
		def my_spor(onceword) # MY SPEASE or
			onceword.gsub(/\|$/,"").gsub("　"," ").split(" ").map{|ww| "("+ww+")" }.compact.join(".*")
		end
	end # class << self

end # module DB


module GUISET

	def self.FarstSet(baseseet)
		subformtop = TkToplevel.new(baseseet).withdraw
		subformtop.title("まず初期設定をしてください")
		TkLabel.new(subformtop,text:"リストを作成するには、\n設定の検索設定からディレクトリと条件を設定して、\n検索開始ボタンを押してください").pack(ipadx:5,ipady:5,padx:5,pady:5,side:'top')
		la = TkLabel.new(subformtop,text:"正しく実行するためには拡張子別実行プログラムも設定してください").pack(ipadx:5,ipady:5,padx:5,pady:5,side:'top')
		subformtop.wm_protocol('WM_DELETE_WINDOW',proc{ subformtop.destroy() } )
		subformtop.deiconify()
		la.focus
		nil
	end
	
	##-- ディレクトリ選択
	def self.ChooseDirectory(baseseet,indir=Dir.pwd)
		subformtop = TkToplevel.new(baseseet).withdraw
		subformtop.title("ディレクトリ選択")
		#- GUI　部品
		TkLabel.new(subformtop,text:"フルパス").pack(side:'top')
		g_nowdir = TkText.new(subformtop,relief:'sunken',width:50,height:2).pack(side:'top',padx:2,pady:2,fill:'x' )
		hsize = 10
		tlrfram = TkFrame.new(subformtop).pack(side:'top',padx:2,pady:2,fill:'both',expand:true)
		
			lframe  = TkFrame.new(tlrfram,padx:5,pady:5).pack(side:'left',fill:'y')
				TkLabel.new(lframe,text:"ドライブ").pack(side:'top')
				g_drive_select = TkListbox.new(lframe , height:hsize , width:6 ,selectmode:'single' ).pack(side:'left',fill:'y')
				
			rframe = TkFrame.new(tlrfram,padx:5,pady:5,relief:'groove',borderwidth:1).pack(side:'left',fill:'both',expand:true)
				TkLabel.new(rframe,text:"ディレクトリ一覧").pack(side:'top')
				g_list = TkListbox.new(rframe,height:hsize,width:40,selectmode:'single').pack(side:'left',fill:'both',expand:true)
				
		g_bot   = TkButton.new(subformtop,text:'決定',width:25,borderwidth:3).pack(padx:3,pady:3,side:'bottom')

		#- リストのスクロール設定 width
		scroll = TkScrollbar.new(rframe,orient:'vertical').pack(side:'right',fill:'y')
		g_list.yscrollcommand( proc{|*args| scroll.set(*args) } )
		scroll.command( proc{|*args| g_list.yview(*args) } )

		# ListBoxにディレクトリ情報表示するproc
		viewdir = Proc.new{
			tmp = g_nowdir.value ; g_nowdir.value = tmp.gsub("\\","/") # pathの￥を/に変更
			g_list.clear
			dirlist = ["../"] +  Dir.glob(g_nowdir.value+"/*/").map{|aa| File.basename(aa)+"/" }
			g_list.insert('end', *dirlist )
		}
	
		# 初期設定はカレントディレクトリ
		g_nowdir.value = Dir.pwd 
		g_nowdir.value = indir if indir.size > 3 # 入力Dirが3文字以上なら書き換え
		viewdir.call() #- 初期カレントディレクトリ描画
		
		#- ドライブ検索
		list_drive = []
		("C".."Z").to_a.each{|drive| list_drive << "#{drive}:/" if File.exist?("#{drive}:/") }
		g_drive_select.insert('end', *list_drive )
		
		#- ディレクトリ移動処理のproc
		driveproc = Proc.new{
			if g_list.curselection.size > 0
				getstr = g_list.value[ g_list.curselection[0] ]
				tmpnow = g_nowdir.value
				nextdir = ( tmpnow + "/" + getstr ).gsub("//","/")
				nextdir = File.dirname( g_nowdir.value ) if ( getstr == "../" )
				g_nowdir.value = nextdir
			elsif g_drive_select.curselection.size > 0
				getstr = g_drive_select.value[ g_drive_select.curselection[0] ]
				g_nowdir.value = getstr
			end
			viewdir.call()
		}
		#- リストをダブルクリックしたらディレクトリ移動
		subformtop.bind('Double-1', driveproc )

		#- 決定処理
		last_value = ""
		endproc = Proc.new{ driveproc.call
							last_value = g_nowdir.value
							subformtop.destroy()     }
		g_bot.command(endproc)
		
		# windowの右上　xボタンが押されたとき設定
		subformtop.wm_protocol('WM_DELETE_WINDOW',proc{ subformtop.destroy() } )

		#- wait
		subformtop.deiconify()
		g_drive_select.focus
		subformtop.set_grab
		subformtop.wait_destroy()
		subformtop.release_grab

		return(last_value) # return Directory Path String
		
	end  # def self.ChooseDirectory(baseseet,indir="")

	##-- 追加削除機能付きリストボックス
	class ListSet
		def initialize(baseform,word,movesw = false,sublistsw=false)
			@label = word
			@root = TkFrame.new(baseform){relief 'groove';borderwidth 1;padx 1; pady 1} # .pack(side:'left',anchor:'w',fill:'both',expand:true)
			TkLabel.new(@root, text: word ).pack(side:'top',anchor:'w')
			
			#- listbox + scroll
			lframe = TkFrame.new(@root).pack(side:'top',anchor:'w',fill:'both',expand:true)
				main_list_left    = TkFrame.new(lframe).grid(row:1, column:1 ,sticky:"news") # .pack(side:'top',anchor:'w',fill:'both',expand:true)
					@list = TkListbox.new(main_list_left,height: 6,width: 15,selectmode: 'multiple',activestyle:'non').pack(side:'left',anchor:'w',fill:'both',expand:true)
					#- リストのスクロール設定
					scroll = TkScrollbar.new(main_list_left){ orient 'vertical' }.pack(side:'left',anchor:'e',fill:'y')
					@list.yscrollcommand(proc { |*args| scroll.set(*args) })
					scroll.command(proc { |*args| @list.yview(*args) })

				## サブリスト start
				@sublist1 = nil
				@sublist2 = nil
				@sublist3 = nil
				
				@sublist3listsize = 0 # koko
				@sublist3list = []
				if sublistsw #  ,expand:true

					# koko
					1.upto(@sublist3listsize).each{
						mllist = TkListbox.new(main_list_left,height: 6,width: 5,selectmode: 'multiple',activestyle:'non').pack(side:'left',anchor:'w',fill:'both',expand:true)
						mllistscroll = TkScrollbar.new(main_list_left){ orient 'vertical' }.pack(side:'left',anchor:'e',fill:'y')
						mllist.yscrollcommand(proc { |*args| mllistscroll.set(*args) })
						mllistscroll.command(proc { |*args| mllist.yview(*args) })
						@sublist3list << mllist
					}

					sub_main = TkFrame.new(lframe).grid(row:1, column:2 ,sticky:"news") #.pack(side:'right',anchor:'w',fill:'both',expand:true)
					TkLabel.new(sub_main, text: "サブ1" ).pack(side:'top',anchor:'w',fill:'x')
					sub_list_top    = TkFrame.new(sub_main).pack(side:'top',anchor:'w',fill:'both',expand:true)
					
					movebotton = TkFrame.new(sub_main).pack(side:'top',anchor:'w',fill:'x')

					TkLabel.new(sub_main, text: "サブ2" ).pack(side:'top',anchor:'w',fill:'x')
					sub_list_bottom = TkFrame.new(sub_main).pack(side:'top',anchor:'w',fill:'both',expand:true)
						## sublist--------------------------
						@sublist1 = TkListbox.new(sub_list_top,height: 6,width: 10,selectmode: 'multiple',activestyle:'non').pack(side:'left',anchor:'w',fill:'both',expand:true)
						#- リストのスクロール設定
						scroll1 = TkScrollbar.new(sub_list_top){ orient 'vertical' }.pack(side:'left',anchor:'e',fill:'y')
						@sublist1.yscrollcommand(proc { |*args| scroll1.set(*args) })
						scroll1.command(proc { |*args| @sublist1.yview(*args) })
						## sublist--------------------------
						@sublist2 = TkListbox.new(sub_list_bottom,height: 6,width: 10,selectmode: 'multiple',activestyle:'non').pack(side:'left',anchor:'w',fill:'both',expand:true)
						#- リストのスクロール設定
						scroll2 = TkScrollbar.new(sub_list_bottom){ orient 'vertical' }.pack(side:'left',anchor:'e',fill:'y')
						@sublist2.yscrollcommand(proc { |*args| scroll2.set(*args) })
						scroll2.command(proc { |*args| @sublist2.yview(*args) })
						
						# koko
						## sublist--------------------------
						#@sublist3 = TkListbox.new(sub_list_bottom,height: 6,width: 10,selectmode: 'multiple',activestyle:'non').pack(side:'left',anchor:'w',fill:'both',expand:true)
						#- リストのスクロール設定
						#scroll3 = TkScrollbar.new(sub_list_bottom){ orient 'vertical' }.pack(side:'left',anchor:'e',fill:'y')
						#@sublist3.yscrollcommand(proc { |*args| scroll3.set(*args) })
						#scroll3.command(proc { |*args| @sublist3.yview(*args) })

					lframe.grid_columnconfigure(2,weight: 1)

					## submove
					oyalist = @list
					sublist1 = @sublist1
					sublist2 = @sublist2
					
					submove = proc{|key|
						l_a = oyalist
						l_a1 = nil
						l_a2 = nil
						l_b = oyalist
						if key == 6
							l_a = oyalist
							l_b = sublist1
						elsif key == 2 
							l_a = sublist1
							l_b = sublist2
						elsif key == 4
							l_a1 = sublist1
							l_a2 = sublist2
							l_b = oyalist
						elsif key == 8
							l_a = sublist2
							l_b = sublist1
						end
						proc{
							if l_a1 != nil || l_a2 != nil
								l_a = l_a2
								if l_a1.curselection.size > l_a2.curselection.size
									l_a = l_a1
								end
							end
							l_a.curselection.each{|curselnum|
								if l_a.nearest(0) <= curselnum && curselnum <= l_a.nearest(2000)
									tmw = l_a.value[ curselnum ]
									l_a.delete( curselnum )
									l_b.insert(0,tmw)
									l_b.yview(0)
									break
								end
							}
						}
					}
					TkButton.new(movebotton,text:'→').pack(side:'left',fill:'x').command( submove.call(6) )
					TkButton.new(movebotton,text:'↓').pack(side:'left',fill:'x').command( submove.call(2) )
					TkButton.new(movebotton,text:'↑').pack(side:'left',fill:'x').command( submove.call(8) )
					TkButton.new(movebotton,text:'←').pack(side:'left',fill:'x').command( submove.call(4) )
					
					@sublist1.bind('Double-1',proc{|ww,yy| cpsub(ww,yy) },"%W","%y")
					@sublist2.bind('Double-1',proc{|ww,yy| cpsub(ww,yy) },"%W","%y")
					
				end
				## サブリスト end
				lframe.grid_columnconfigure(1,weight: 3)
				lframe.grid_rowconfigure(1,weight: 100)
				
			#-　ボタン
			bframe = TkFrame.new(@root).pack(side:'bottom',anchor:'w',fill:'x')
				if movesw
					oyalist_base = @list
					sub1 = nil
					sub2 = nil
					if sublistsw
						sub1 = @sublist1
						sub2 = @sublist2
					end
					subf_2 = TkFrame.new(bframe){
						uee =  TkButton.new(self,text:' ↑ 上へ ↑ ').pack(ipadx:2,ipady:2,padx:2,pady:2,side:'left',fill:'x')
						sita =  TkButton.new(self,text:' ↓ 下へ ↓ ').pack(ipadx:2,ipady:2,padx:2,pady:2,side:'left',fill:'x')
						moveproc =proc{|mm|
							proc{ # プロックを返すプロック
								oyalist = oyalist_base
								if oyalist.curselection.size < 1 && sublistsw
									if sub1.curselection.size > 0
										oyalist = sub1
									elsif sub2.curselection.size > 0
										oyalist = sub2
									end
								end
								oyalist.curselection.each{|curselnum|
									if oyalist.nearest(0) <= curselnum && curselnum <= oyalist.nearest(2000)
										tmw = oyalist.value[ curselnum ]
										oyalist.delete( curselnum )
										if mm == -1
											oyalist.insert('end',tmw)
											oyalist.yview('end')
										else
											oyalist.insert(0,tmw)
											oyalist.yview(0)
											#oyalist.selection_set  0
										end
										break
									end
								}
							}
						}
						uee.command(moveproc.call(0))
						sita.command(moveproc.call(-1))
					}.pack(side:'left',fill:'x')
				end
				@addbox = TkEntry.new(bframe, width: 6 ).pack(ipadx:2,ipady:2,padx:2,pady:2,side:'left',fill:'x',expand:true)
				@bottun_add = TkButton.new(bframe,text:'追加').pack(ipadx:2,ipady:2,padx:2,pady:2,side:'left',fill:'x')
				bottun_del = TkButton.new(bframe,text:'削除').pack(ipadx:2,ipady:2,padx:2,pady:2,side:'left',fill:'x')
				# 追加削除のコマンド設定
				bottun_del.command( proc{ delsub } )
				@bottun_add.command( proc{ addsub } )
				@addbox.bind('Return',proc{ addsub })
				
			@list.bind('Double-1',proc{|ww,yy| cpsub(ww,yy) },"%W","%y")

			nil
		end
		def cpsub(ww,yy)
				#doublenum = @list.nearest(yy)
				#@addbox.value = @list.value[doublenum]
				doublenum = ww.nearest(yy)
				@addbox.value = ww.value[doublenum]
		end
		def delsub
			if @addbox.value.size > 0
				@addbox.value = ""
			else
				[ @list , @sublist1 , @sublist2 ].select{|ob| ob!=nil }.each{|oblist|
					oblist.curselection.each{|dnum|
						if oblist.nearest(0) <= dnum && dnum <= oblist.nearest(2000)
							# @addbox.value =oblist.value[dnum] # 削除したワードを入力に退避
							oblist.delete(dnum)
							break
						end
					}
				}
			end
		end
		def addsub
			if @addbox.value.size > 0
				cksw = true
				[ @list , @sublist1 , @sublist2 ].select{|ob| ob!=nil }.each{|oblist|
					fi = oblist.value.find_index(@addbox.value)
					if fi != nil
						cksw = false
						oblist.selection_set fi
					end
				}
				if cksw
					@list.selection_clear 0
					@list.insert(0, @addbox.value.gsub("||","|").gsub(/\|$/,"") ) # koko
					@list.selection_set  0
				end
			end
			@addbox.value = ""
		end
		attr_accessor :label,:list,:addbox,:root,:bottun_add
		attr_accessor :sublist1,:sublist2
	end # class ListSet
	
	###--- 疑似スクロールバーclass　TkVariableを使用しないバージョン
	class MvScroll 
		FontS = "\"MS UI Gothic\" 8"
		def initialize(baseobj)
			@baseobj = baseobj
			@nowpos = 0 # viewの位置
			@subproc = Proc.new{}
			@root = nil
			@pos_offset = Proc.new{|offset,full| ## Procを返すProc
				#GC.start
				proc{ # スクロール用proc
					old_nowpos = @nowpos
					if full
						@nowpos = @root.get()
					else
						@nowpos += offset
					end
					@nowpos = 0 if @nowpos < 0
					@root.set(@nowpos)
					if old_nowpos != @root.get()
						@subproc.call
					end
				}
			}
			@root = TkScale.new(@baseobj,
					'showvalue'=>'true',
					'from'=>0,
					'orient'=>'vertical',
					'font'=>FontS,
					)
			@root.command( @pos_offset.call(0,true) )
			@root.set(0)
		end
		def cleate_button(title='null',offsetnum)
			aa = @pos_offset.call(offsetnum,false)
			TkButton.new(@baseobj, text: title , command: aa ) # ,'font'=>FontS ,  padx: -1 , pady: -1 )
		end
		def set_Mouse_wheel(checkform,offset) # 指定したフォームにマウスホイール設定
			aa = @pos_offset.call(-offset,false)
			bb = @pos_offset.call(offset,false)
			checkform.bind('Button-1'    , proc{|w| w.focus },"%W" ) # 指定したフォームにフォーカス（マウスホイール有効にするため） Enter
			checkform.bind('MouseWheel', proc{|dD| dD > 0 ? aa.call : bb.call } ,"%D") # マウスホイール設定
			
		end 
		def command(subcommand) # スクロールと連動するProc 指定
			@subproc = subcommand
		end
		def basepos(memsize,guisize) # データ個数,表示個数
			@root.to(memsize-1)
			max = memsize - guisize
			@nowpos = max if @nowpos >= max
			@nowpos = 0 if @nowpos < 0
			nil
		end
		attr_accessor :nowpos,:root
	end # class MvScroll
	
end


module Seet1
	@sort_weight_save = true
	@view_main = []  # GUIviewテーブルのリスト変数[path,all_time,max_time,exec_num,lasttime,sw,button]
	@f3_scb2 = nil
	@f2_mvl = nil
	@match = Regexp.compile( "." , Regexp::IGNORECASE )
	@match_not = Regexp.compile( "." , Regexp::IGNORECASE )
	@element_button = Hash.new
	@grid_info_list = []
	@grid_info_step = 0
	@unpackbutton = nil
	@uncheck_onoff = nil
	@num_button_call = nil
	@sortmagen = nil
	@reverse = nil
	@chokkin_musi = nil
	@topview = nil
	@newexec_musi = nil
	@presort = [ proc{0} , 0 , "nil" , "nil" ]
	# key
	Nere_Musi = 'nere_musi'
	SortMagenKey = 'sortmagen'
	SortDateMagenKey = 'sortdatemagen'
	RetuStep = 'step'
	# mem
	BoWi = 'borderwidth'
	Groove = 'groove' # relief: flat (平坦)、raised (出っぱり)、sunken (引っ込み)、groove (溝)、ridge (土手) 
	Sunk = 'sunken'
	Rais = 'raised'
	Stic = 'sticky'
	Ne = 'news'
	BOTH = 'both'
	ReOn = 'readonly'
	Norm = 'normal'
	IROsiro ='#FFFFFF'
	IROaka  ='#FF77FF'
	IROao  ='#77FFFF'
	# word
	FileMakeOFF = '作成日を非表示'
	FileWiteOFF = '更新日を非表示'
	FileMakeON  = '作成日 を 表示'
	FileWiteON  = '更新日 を 表示'
	NumButton_EXEC = "番号ボタン挙動\n『実行する』"
	NumButton_OPEN = "番号ボタン挙動\nFILEの場所開く"
	Ber_ToLeft = '左に配置'
	Ber_ToRigt = '右に配置'
	UNcheckOFF = "無効を\n非表示中"
	UNcheckON  = "無効を\n表示中"
	#
	LastTime = Kline::Lasttime # 'lasttime'
	OldTime = Kline::Oldtime #'oldtime' # 作成日
	NewTime = Kline::Newtime #'newtime' # 更新日
	CheckYES = Kline::Yes #'yes'
	CheckNO = Kline::No #'no'
	SedStr = ' ... '
	Tbx = 13
	ENm = 5
	UniPro = proc{|ws,ri,pr|
		proc{
			width ws
			relief Sunk
			grid(row:ri, column:pr  ,sticky:Ne) # news
		}
	}
	class << self
		attr_accessor :f2_mvl
		attr_accessor :sort_weight_save
		class ViewSet
			def initialize(topform,ri,pr) 
				@path     = TkEntry.new(topform, &UniPro.call(50,ri,pr)    )# }.bind('Key',proc{Seet1.review})
				# koko コピー機能
				#@path.bind('Button-3', proc{|w| p "button2" ; p w.get("sel.first", "sel.last") },"%W"  )

				@all_time = TkEntry.new(topform, &UniPro.call(ENm,ri,pr+1) )
				@max_time = TkEntry.new(topform, &UniPro.call(ENm,ri,pr+2) )
				@exec_num = TkEntry.new(topform, &UniPro.call(ENm,ri,pr+3) )
				@lasttime = TkEntry.new(topform, &UniPro.call(Tbx,ri,pr+4) )
				@oldtime  = TkEntry.new(topform, &UniPro.call(Tbx,ri,pr+5) )
				@newtime  = TkEntry.new(topform, &UniPro.call(Tbx,ri,pr+6) )

				@sort_weight = TkEntry.new(topform, width:2 , relief:Sunk )
				@sort_weight.bind('KeyRelease', proc{|k| Seet1.weight_save() }, "%K") # ButtonRelease
				if Seet1.sort_weight_save
					@sort_weight.grid(row:ri, column:3  ,sticky:Ne)
				end

				@onoff = TkCheckButton.new(topform,
								onvalue:CheckYES,
								offvalue:CheckNO).grid(row:ri, column:2 ,sticky:Ne)
				@button =  TkButton.new(topform,text:ri,width:ENm, pady:-1, padx:-1).grid(row:ri, column:1,sticky:Ne)
				@sw = TkVariable.new( CheckYES )
				@onoff.variable(@sw).command( proc{ DB.nowlist[@button.text.to_i].sw( @sw.value ) if DB.nowlist.size > @button.text.to_i } )
				@button.command( proc{ DB::exec( @button.text.to_i , @button ) if DB.nowlist.size > @button.text.to_i } )
				nil
			end

			attr_accessor :path,:all_time,:max_time,:exec_num,:lasttime,:sw,:button,:oldtime,:newtime,:sort_weight
		end

		def b_label_togle(obj,str1,str2,exec=proc{})
			obj.text == str1 ? obj.text(str2) : obj.text(str1)
			obj.relief == Rais ? obj.relief(Sunk) : obj.relief(Rais)
			obj.background == IROaka ? obj.background(IROao) :obj.background(IROaka)
			exec.call
			nil
		end

		def numbutton_open # 数字ボタンの挙動取得用
			@num_button_call.text
		end
		
		def time_unpack(sw = true)
			if FileMakeOFF == @unpackbutton.text
				if sw
					wo = TkWinfo.geometry($root)
					$root.geometry( wo )
				end
				@grid_info_list = []
				@grid_info_step = 0
			end
			case @unpackbutton.text
			when FileMakeOFF
				@grid_info_list << @element_button[OldTime].grid_info
				@element_button[OldTime].grid_remove
				@view_main.each{|ob|
					@grid_info_list << ob.oldtime.grid_info
					ob.oldtime.grid_remove
				}
				@unpackbutton.text = FileWiteOFF
				@grid_info_step += 1
			when FileWiteOFF
				@grid_info_list << @element_button[NewTime].grid_info
				@element_button[NewTime].grid_remove
				@view_main.each{|ob|
					@grid_info_list << ob.newtime.grid_info
					ob.newtime.grid_remove
				}
				@unpackbutton.text = FileMakeON
				@grid_info_step += 1
			when FileMakeON
				@element_button[OldTime].grid_configure( @grid_info_list.shift )
				@view_main.each{|ob| ob.oldtime.grid_configure(@grid_info_list.shift) }
				@unpackbutton.text = FileWiteON
				@grid_info_step += 1
			when FileWiteON
				@element_button[NewTime].grid_configure( @grid_info_list.shift )
				@view_main.each{|ob| ob.newtime.grid_configure(@grid_info_list.shift) }
				@unpackbutton.text = FileMakeOFF
				@grid_info_step += 1
			end # case @unpackbutton.text
			DB::set_main_win_ini(RetuStep,@grid_info_step)
			if sw
				$root.update
				review()
			end
			nil
		end
				
		def make(seet1)
			###----Seet1 Main Frame
			f1_top = TkFrame.new(seet1,relief: Groove,BoWi=>2,padx:2,pady:2).pack(side:'top' , fill:'x',expand:true)
			@f2_mvl = TkFrame.new(seet1,relief: Groove,BoWi=>1,padx:1,pady:1).pack(side:'right' , fill:BOTH,expand:true)

			###--- 上部ボタン
			
			#- チェックの設定 ---セーブ無し
			@uncheck_onoff = TkLabel.new(f1_top,pady:-1, width: 9,borderwidth:2,font:{size:8},
					relief:Sunk,background:IROaka,text:UNcheckOFF).pack(side:'left',fill:BOTH , ipadx:1,padx:2 )
			@uncheck_onoff.bind( 'Button-1', proc{ b_label_togle(@uncheck_onoff,UNcheckOFF,UNcheckON,proc{review()}) } )

			#--- 絞り込みボタン ---
			fillformobj = nil # fillForm(fillwinopen) # destroyしない 使いまわし用ウインドウ作成
			fillwinopen = TkButton.new(f1_top){
					text "絞り込み\nウインドウ" ; borderwidth 3 ;
					pack(side:'left',fill:BOTH,ipadx:1,padx:2,pady:1) ;
				}
			fillwinopen.command proc{ fillformobj == nil ?  fillformobj = fillForm(fillwinopen) : fillformobj.deiconify } ;

			#--- 縦フレーム ---
			vf_01  = TkFrame.new(f1_top,BoWi=>0,padx:-1,pady:-1).pack(side:'left')
				#--- ソート逆順 ---セーブ無し
				@reverse = TkCheckButton.new(vf_01,borderwidth:1,relief:Groove,padx:-1,pady:-1,
								onvalue:CheckYES,offvalue:CheckNO){font(size:8) ; text "逆順ソート"}.pack(padx:1,side:'top',fill:BOTH)
				#---直近無視 ---セーブ無し
				@chokkin_musi = TkCheckButton.new(vf_01,borderwidth:1,relief:Groove,padx:-1,pady:-1,
								onvalue:CheckYES,offvalue:CheckNO){font(size:8) ; text "直近無視"}.pack(padx:1,side:'top',fill:BOTH)
				@chokkin_musi.variable = TkVariable.new(CheckNO)

			vf_02  = TkFrame.new(f1_top,BoWi=>0,padx:-1,pady:-1).pack(side:'left')
				#--- ソートマージン（±％） ---自動セーブ
				sort_frame1  = TkFrame.new(vf_02,relief: Groove,BoWi=>1,padx:-1,pady:-1).pack(padx:0,side:'top' , fill:BOTH)
					TkLabel.new(sort_frame1){ font(size:8) ; text "並べ替え乱数(±%)" ; pack(side:'left',fill:BOTH) ; }
					@sortmagen = TkEntry.new(sort_frame1){ width 3 ; pack(side:'left') ; }
					@sortmagen.value = ( DB::get_main_win_ini(SortMagenKey) == nil ? 50 : DB::get_main_win_ini(SortMagenKey) )
				#--- ソートマージン（h） ---自動セーブ
				sort_frame2  = TkFrame.new(vf_02,relief: Groove,BoWi=>1,padx:-1,pady:-1).pack(padx:0,side:'top' , fill:BOTH)
					TkLabel.new(sort_frame2){ font(size:8) ; text "日付並替乱数(±h)" ; pack(side:'left',fill:BOTH) ; }
					@sortdatemagen = TkEntry.new(sort_frame2){ width 3 ; pack(side:'left') ; }
					@sortdatemagen.value = ( DB::get_main_win_ini(SortDateMagenKey) == nil ? 24*7 : DB::get_main_win_ini(SortDateMagenKey) )

			#--- 上半分固定 ---セーブ無し　@topview　variable:TkVariable.new(CheckYES)
			@topview = TkCheckButton.new(f1_top,borderwidth:1,relief:Groove,variable:TkVariable.new(CheckYES),
							onvalue:CheckYES,offvalue:CheckNO){font(size:8) ; text "上半分\nTOP固定"}.pack(padx:1,side:'left').bind('Button-1', proc{ Seet1.review() })

#=begin
			#--- 簡易検索
			wordf  = TkFrame.new(f1_top,relief: Groove,BoWi=>1,padx:2,pady:2).pack(padx:2,pady:2,side:'left' , fill:BOTH)
			@wordsort = TkEntry.new(wordf){ width 16 ; pack(side:'top', fill:BOTH) ; }
			@wordsort.value = "検索ワード入力しEnter"
			wordsortproc = proc{
				karistr = @wordsort.value
				karistr = DB.my_spor( karistr )
				@match = Regexp.compile( DB.my_esc( karistr[0..-1] ) , Regexp::IGNORECASE ) ## MY_ESCAPE
				sort_proc('path_sort')
				}
			@wordsort.bind('Return',wordsortproc )
			#--- 簡易not検索
			notframe = TkFrame.new(wordf,BoWi=>0,padx:-1,pady:-1).pack(side:'top' , fill:BOTH)
				TkLabel.new(notframe){ font(size:8) ; text "無視:" ; pack(side:'left',fill:BOTH) ; }
				@match_not = TkEntry.new(notframe){ width 6 ; pack(side:'top', fill:BOTH) ; }
				@match_not.value = "無視ワード"
				@match_not.bind('Return',wordsortproc )
#=end
			#--- 個数変更 ---自動セーブ
			listline = DB.main_list_view_num()
				re_label_1 = "ランダム\n実行回数" # background:IROaka
				re_label_2 = "順番\n実行回数"
				re_label_root = nil
				re_label_frame = TkFrame.new(f1_top){|mf|
					relief Groove
					borderwidth 1
					pack(padx:1,side:'left' , fill:'x')
					tmpenum = DB.rundam_exec_num() > listline/2 ?  listline/2 : DB.rundam_exec_num()
					re_label_root = TkLabel.new(mf,font:{size:8}).pack(side:'left').text(re_label_1)
					re_label_root.background(IROaka)
					re_label_root.bind( 'Button-1', proc{
							if re_label_root.text == re_label_1
								re_label_root.text(re_label_2)
								re_label_root.background(IROao)
							elsif re_label_root.text == re_label_2
								re_label_root.text(re_label_1)
								re_label_root.background(IROaka)
							else
								re_label_root.text(re_label_1)
								re_label_root.background(IROaka)
							end
						} )
					mainlistnum = TkSpinbox.new(mf,to: listline/2 ,from: 1 ,increment:1,width:3).pack(side:'left',fill:BOTH)
					mainlistnum.set(tmpenum)
					mainlistnum.command( proc{ DB.rundam_exec_num( mainlistnum.get.to_i ) } )
				}
			#--- ランダムに連続実行 ---
			randam_exec = TkLabel.new(f1_top,pady:-1,borderwidth:4,relief:Rais,height: 2 ,
					text: DB::RAND_EXEC_1).pack(side:'left',fill:BOTH,ipadx:1,padx:2)
			randexec_proc = proc{
				num_arr = @view_main.map{|ss| ss.button.text.to_i }
				if re_label_root.text == re_label_1
					DB.exec( (num_arr[0..num_arr.size()/2].shuffle![0..DB.rundam_exec_num()-1]).delete_if{|nn| nn >= DB.nowlist.size } , randam_exec )
				else
					DB.exec( (num_arr[0..DB.rundam_exec_num()-1]).delete_if{|nn| nn >= DB.nowlist.size } , randam_exec )
				end
			}
			randam_exec.bind( 'ButtonPress-1', proc{ randam_exec.relief(Sunk) } )
			randam_exec.bind( 'ButtonRelease-1', proc{ randam_exec.relief(Rais) ;randexec_proc.call  } )

#--- side:right

			###--- unpack ---
			@unpackbutton = TkButton.new(f1_top,pady:-1, text: FileMakeOFF , borderwidth:4 ).pack(side:'right',fill:BOTH , ipadx:1,padx:2,)
			@unpackbutton.command( proc{ time_unpack } )

			###--- avesort ---
			TkButton.new( f1_top , borderwidth:2 ,font:{size:8}, command: proc{ sort_proc('avetime')  } ,
						text:DB::J_AVE_EXEC+"\nソート" ).pack(side:'right',fill:BOTH , ipadx:0,padx:0)
			# ファイルサイズソート
			#TkButton.new( f1_top , borderwidth:2 ,font:{size:8}, command: proc{ sort_proc('filesize') } ,
			#			text:DB::J_FILESIZE+"\nソート" ).pack(side:'right',fill:BOTH , ipadx:0,padx:0)

###--- 疑似スクロールバー 0列目か１００列目 2行目～100行目をぶち抜き
			@f3_scb2  = TkFrame.new(@f2_mvl  ,BoWi=>1).grid(row:2, column:0,rowspan:100,Stic=>Ne)
			scbutton1 = TkButton.new(@f3_scb2, text: Ber_ToRigt ) # 現在は無効.pack(side:'top',fill:BOTH)
			@mvscroll = GUISET::MvScroll.new(@f3_scb2)
			@mvscroll.command( proc{ Seet1.review() } )
			@mvscroll.cleate_button('↑10',-10).pack(side:'top' , fill:'x')
			@mvscroll.cleate_button('↑ 1', -1).pack(side:'top' , fill:'x')
			@mvscroll.cleate_button('↓10', 10).pack(side:'bottom' , fill:'x')
			@mvscroll.cleate_button('↓ 1',  1).pack(side:'bottom' , fill:'x')
			@mvscroll.root.pack(side:'right' ,anchor:'e', fill:BOTH,expand:true)
			#--- スクロールバーの列変更　０列＜＝＞１００列 ---
			scbutton1.command(
				proc{	@f3_scb2.ungrid()
						if scbutton1.text == Ber_ToLeft
							@f3_scb2.grid(row:2, column:0,rowspan:100,Stic=>Ne)
							scbutton1.text = Ber_ToRigt
						else
							@f3_scb2.grid(row:2, column:100,rowspan:100,Stic=>Ne)
							scbutton1.text = Ber_ToLeft
						end
					}
			)
			
			#--- メインリスト @f2_mvl ###########################################
			
			#--- 1行目、題名＋ソートボタン path用 ---
			p_sortbotton_jp = [ 'path_昇順' , 'path_降順' , 'path_ランダム' ]
			p_sortbotton    = [ 'path_A' , 'path_B'  , 'path_R' ] 
			path_retu = 10
			ypos = 1 
			path_sort_f = TkFrame.new(@f2_mvl).grid(row:ypos, column:path_retu,Stic=>Ne)
				p_sortbotton.each_index{|ww|
						@element_button[p_sortbotton[ww]] = TkButton.new( path_sort_f , borderwidth:1 , 
								command: proc{ sort_proc(p_sortbotton[ww]) } ,
								text:p_sortbotton_jp[ww] ).pack(side:'left',fill:BOTH,expand:true)
				}
			#--- 1行目、題名＋ソートボタン ---
			sortbotton_jp = [ DB::J_SUM_EXEC, DB::J_MAX_EXEC,  DB::J_EXEC_NUM,  DB::J_LAST_EXEC, DB::J_OldTime, DB::J_NewTime ]
			sortbotton    = [ 'alltime', 'maxtime', 'exenum', LastTime, OldTime     , NewTime ]
			sortbotton.each_index{|ww|
					@element_button[sortbotton[ww]] = TkButton.new( @f2_mvl , borderwidth:1 , 
							command: proc{ sort_proc(sortbotton[ww]) } ,
							text:sortbotton_jp[ww] ).grid(row:ypos, column:ww+path_retu+1,Stic=>Ne)
			}

			#---'有/無効' 
			xpos = 2 # xpos : 2
			@element_button['sw']=TkLabel.new(@f2_mvl,font:{size:8},relief:Rais,borderwidth:1,text:"有無\n効効",padx:-1).grid(row:ypos,column:xpos,Stic=>Ne)
			@element_button['sw'].bind("ButtonPress-1"   , proc{ @element_button['sw'].relief Sunk } )
			@element_button['sw'].bind("ButtonRelease-1" , proc{ @element_button['sw'].relief Rais ; sort_proc('sw') } )

			#---'sort_weight' 
			xpos = 3
			@element_button['sort_weight']=TkLabel.new(@f2_mvl,font:{size:8},relief:Rais,borderwidth:1,text:"w",padx:-1)
			@element_button['sort_weight'].bind("ButtonPress-1"   , proc{ @element_button['sort_weight'].relief Sunk } )
			@element_button['sort_weight'].bind("ButtonRelease-1" , proc{ @element_button['sort_weight'].relief Rais ; sort_proc('sort_weight') } )
			if Seet1.sort_weight_save
				@element_button['sort_weight'].grid(row:ypos,column:xpos,Stic=>Ne)
			end
			
			#- 数字ボタンを押した挙動 --- 
			xpos = 0 # xpos : 0-1
			@num_button_call = TkLabel.new(@f2_mvl,font:{size:8},padx:-1,pady:-1, width:10,borderwidth:2,
					relief:Rais,background:IROao,text:NumButton_EXEC).grid(padx:1,pady:2,row:ypos, column:xpos,columnspan:2,Stic=>Ne)
			@num_button_call.bind( 'Button-1', proc{ b_label_togle(@num_button_call,NumButton_EXEC,NumButton_OPEN) } )
			
; logging( TC.setget( __FILE__ , __LINE__  ) , "seet1main1" ) ; 

			#--- 2行目以降 メインリスト表 ---
			listline = DB.main_list_view_num()
			ypos = 2 
			ypos.upto(ypos+listline) {|ri|
				@view_main << ViewSet.new(@f2_mvl,ri,path_retu)
				@mvscroll.set_Mouse_wheel( @view_main[-1].path ,5) # マウスホイールのスクロール設定
			}
; logging( TC.setget( __FILE__ , __LINE__  ) , "seet1main2" ) ;

			#--- 一列目（ファイル名）の横幅をウィンドウサイズと連動設定
			@f2_mvl.grid_columnconfigure(path_retu,weight: 100)

			if DB::get_main_win_ini(RetuStep) != nil
				0.upto( DB::get_main_win_ini(RetuStep)-1 ){ time_unpack(false) }
			end

			return seet1

		end # def make(seet1)

###--- 重み保存
		def weight_save
			# koko sort_weight
			@view_main.each_index{|bl|
				if @view_main[bl].button.text =~ /\d+/
					pos = @view_main[bl].button.text.to_i
					next if pos >= DB.nowlist.size
					if ( DB.nowlist[pos].sort_weight_io() != @view_main[bl].sort_weight.value.to_i ) \
						&& @view_main[bl].sort_weight.value =~ /\d+/
						if ( @view_main[bl].sort_weight.value.size == 1 )
							DB.nowlist[pos].sort_weight_io( @view_main[bl].sort_weight.value.to_i )
						end
					end
				end
			}
		end
		
###--- ソート処理
		Sort_ra = proc{[-1,1,0,-1 ,1].sample(1)[0]}
		def sort_proc(sort_col) # ソート処理
			random = Random.new
			
			#-数値ソート
			magen = @sortmagen.value.to_i * 0.01
			DB::set_main_win_ini(SortMagenKey, ( @sortmagen.value.to_i * 0.01 * 100.0 ).round )
			range_max = 1.0 + magen
			range_min = 1.0 - magen
			mr_c = proc{|aa,bb|
				if    ( aa * range_max < bb ) ; 1
				elsif ( aa * range_min > bb ) ;-1
				else ; 0
				end
			}

			#-日付ソート
			datemagen = eval( @sortdatemagen.value ).to_i
			DB::set_main_win_ini(SortDateMagenKey, ( datemagen * 0.01 * 100.0 ).round )
			nowtime = Time.now.to_i 
			range_time = 3600*datemagen
			musirange = nowtime - range_time
			pm_data = proc{|aa,bb|
				ret = 0
				   if ( aa + range_time < bb )
						ret =  1
				elsif ( aa - range_time > bb )
						ret = -1
				else
						ret = 0 
				end
				ret
			}
			
			#-直近無視用
			chokkin_musi  = proc{|aa,bb|0}
			if @chokkin_musi.variable == CheckYES
				chokkin_musi = proc{|aa,bb|
					ret = 0
					ret = 1 if ( aa.lasttime > musirange )
					ret
				}
			end

			#-各種ソートproc
			# 数値でソートなら mr_c.call(a,b)
			sort_alltime = proc{|aa,bb| mr_c.call( aa.all_time , bb.all_time ) }
			sort_maxtime = proc{|aa,bb| mr_c.call( aa.max_time , bb.max_time ) }
			sort_execnum = proc{|aa,bb| mr_c.call( aa.exec_num , bb.exec_num ) }
			sort_avetime = proc{|aa,bb| mr_c.call( aa.all_time/aa.exec_num , bb.all_time/bb.exec_num ) }
			sort_filesize  = proc{|aa,bb| mr_c.call(aa.fsize ,bb.fsize) }
			# 日付でソートなら pm_data.call(a,b)
			sort_lasttime = proc{|aa,bb| pm_data.call(aa.lasttime,bb.lasttime) }
			sort_oldtime  = proc{|aa,bb| pm_data.call(aa.oldtime ,bb.oldtime) }
			sort_newtime  = proc{|aa,bb| pm_data.call(aa.newtime ,bb.newtime) }
			# yes/no　ソート
			#sort_sw      =  proc{|aa,bb| aa.sw<=>bb.sw } # noが上
			sort_sw      =  proc{|aa,bb| bb.sw<=>aa.sw } # noが下
			# sort_weight　ソート
			sort_weight_proc = proc{|aa,bb|
				magen > rand ? 0 : bb.sort_weight_io <=> aa.sort_weight_io
				} 
			
			## 基本ソート
			hp = proc{|aa,bb| bb<=>aa } # 大きいほうが優先
			hp_muki = 1

			## マッチソート start
			karistr = @match_not.value
			karistr = karistr.gsub(/\|$/,"").gsub("　"," ").split(" ").map{|ww| "("+ww+")" }.compact.join("|")
			match_not = Regexp.compile(karistr[0..-1], Regexp::IGNORECASE )
			notsw = ( "無視ワード" == @match_not.value ) || @match_not.value.size < 1
			sort_match_path = proc{|aa,bb|
				r1 = aa.path.match(@match)
				r2 = bb.path.match(@match)
				nnrr1 = 0
				nnrr2 = 0
				if !notsw
					nr1 = aa.path.match(match_not)
					nr2 = bb.path.match(match_not)
					nnrr1 = nr1.nil? ? 0 : -2
					nnrr2 = nr2.nil? ? 0 : -2
				end
				rr1 = r1.nil? ? 0 : 1
				rr2 = r2.nil? ? 0 : 1
				ret1 = rr2+nnrr2 <=> rr1+nnrr1
			}
			## マッチソート end

			#-ボタン別ソート
			case sort_col
			when 'sort_weight' 
				hp = sort_weight_proc
			when 'path_A'
				hp = proc{|aa,bb|
					ret = aa.path<=>bb.path
					magen > rand ? ret*0 : ret
					}
			when 'path_B'
				hp = proc{|bb,aa|
					ret = aa.path<=>bb.path
					magen > rand ? ret*0 : ret
					}
			when 'path_R'
				hp = proc{|aa,bb| Sort_ra.call }
			when 'alltime' ; hp = sort_alltime
			when 'avetime' ; hp = sort_avetime
			when 'maxtime' ; hp = sort_maxtime
			when 'exenum'  ; hp = sort_execnum
			when 'filesize'  ; hp = sort_filesize
			when LastTime  ; hp = sort_lasttime
			when OldTime   ; hp = sort_oldtime
			when NewTime   ; hp = sort_newtime
			when 'sw'      ; hp = sort_sw
			when 'path_sort'
				hp = sort_match_path
			else
				hp = proc{0}
			end

			#-2次ソート設定
			DB.ini_data[DB::SUB_SORT_SET].sort!{|bb,aa| aa[:weight]<=>bb[:weight]}
			sortlist = []
			## 
			DB.ini_data[DB::SUB_SORT_SET].each{|obj|
				adda = [  obj[:value] , obj[:weight] ]
				case obj[:key]
				when DB::J_PRESORT # J_PRESORT = '直前のソート'
					sortlist << [@presort[0] , @presort[1] , obj[:weight] ]
				when DB::J_WORDFIND # ワード検索 ## ワードソートの2次ソート有効
					sortlist << [sort_match_path , 1 , obj[:weight] ]      if @presort[2] != 'path_sort'
				when DB::J_WEIGHT # sort_weight
					sortlist << [sort_weight_proc ] + adda       if @presort[2] != 'sort_weight'
				when DB::J_EXEC_NUM
					sortlist << [sort_execnum ] + adda      if @presort[2] != 'exenum'
				when DB::J_LAST_EXEC
					sortlist << [sort_lasttime ] + adda      if @presort[2] != LastTime
				when DB::J_AVE_EXEC
					sortlist << [sort_avetime ] + adda      if @presort[2] != 'avetime'
				when DB::J_SUM_EXEC
					sortlist << [sort_alltime ] + adda      if @presort[2] != 'alltime'
				when DB::J_MAX_EXEC
					sortlist << [sort_maxtime ] + adda      if @presort[2] != 'maxtime'
				when DB::J_OldTime
					sortlist << [sort_oldtime ] + adda      if @presort[2] != OldTime
				when DB::J_NewTime
					sortlist << [sort_newtime ] + adda      if @presort[2] != NewTime
				when DB::J_FILESIZE
					sortlist << [sort_filesize ] + adda      if @presort[2] != 'filesize'
				end
			}
			
			#-ボタンソートの向き設定
			hp_muki_tmp = sortlist.find{|obj| obj[0] == hp } 
			hp_muki = hp_muki_tmp == nil ? 1 : hp_muki_tmp[1]
			
			#- ソート前 重み保存
			weight_save() # sort_weight
			#-実際のソート
			sortlist.delete_if{|obj| obj[2] <= 10 }
			DB.nowlist.shuffle!
			DB.nowlist.sort!{|aa,bb|
				sort1 = chokkin_musi.call(aa,bb) # 直近無視
				sort1 = hp.call(aa,bb) * hp_muki if sort1 == 0
				sortlist.each{|pr|
					break if sort1 != 0
					next if pr[0] == hp
					sort1 = pr[0].call(aa,bb) * pr[1]
				}
				sort1 = sort_weight_proc.call(aa,bb) if sort1 == 0 # 重み sort_weight
				sort1 == 0 ? Sort_ra.call : sort1
			}
			
			#-逆順
			DB.nowlist.reverse! if @reverse.variable == CheckYES
			
			# 直前のソート保存
			@presort[0] = hp.clone
			@presort[1] = hp_muki
			@presort[2] = sort_col.clone

			#-再描画
			review()
			
			return nil
		end

		def path_width_offset
			TkWinfo.width( @view_main[0].path )
		end

###--- 再描画処理
		def review() 

			@mvscroll.basepos(DB.nowlist.size,@view_main.size ) # スクロールバーの最大最小値の再設定
			mushioffset = 0
			basepath = @view_main[0].path
			sn = proc{|s| basepath.font.measure( s ) } # 文字列のpix測長Proc
			textbox_box_pix = TkWinfo.width( basepath.path ) # textbox の　pix 幅
			
			if textbox_box_pix < 10
			pre_off = nil
			pre_off = DB.ini_data["window"][:path_width_offset] if DB.ini_data["window"] != nil
			textbox_box_pix = pre_off > path_width_offset ? pre_off : textbox_box_pix if pre_off != nil
			end
			
			scroll_pos = @mvscroll.nowpos
			harf = @topview.variable == CheckYES ? @view_main.size / 2 : 0
			@view_main.each_index{|bl|
				
				nowpos = harf > bl ? 0 : scroll_pos
				pos = bl+ nowpos +mushioffset
				
				if @uncheck_onoff.text == UNcheckOFF ## KOKO
					while pos < DB.nowlist.size #- 1
						if DB.nowlist[pos].sw == CheckNO
							mushioffset += 1 
						else
							break
						end
						pos = bl+ nowpos +mushioffset # 現在のスクロールバーの位置から表示する位置を算出
					end
				end
				
				if pos > DB.nowlist.size - 1
					kuuhaku = "_"
					@view_main[bl].sort_weight.value = kuuhaku
					@view_main[bl].path.value = kuuhaku
					@view_main[bl].all_time.value = kuuhaku
					@view_main[bl].max_time.value = kuuhaku
					@view_main[bl].exec_num.value = kuuhaku
					@view_main[bl].lasttime.value = kuuhaku
					@view_main[bl].oldtime.value = kuuhaku
					@view_main[bl].newtime.value = kuuhaku
					@view_main[bl].sw.set_value(UNcheckOFF)
					@view_main[bl].button.text = pos
					next
				end
				
				#-- path 短縮---
				textbox_str_pix = sn.call( DB.nowlist[pos].path ) # path の pix 幅
				if textbox_str_pix > textbox_box_pix
					strs = DB.nowlist[pos].path.clone
					cutstrpre = strs.slice!(0,3)
					cutstrpre += SedStr
					sumpix = sn.call( cutstrpre )
					spos = (strs.size/2).round
					sumpix += sn.call( strs.slice(spos..-1) )
					while sumpix < textbox_box_pix
						spos-=3
						ck = sumpix
						sumpix += sn.call( strs.slice(spos,3) )
						break if !(ck < sumpix)
					end
					while sumpix > textbox_box_pix
						ck = sumpix
						sumpix -= sn.call( strs.slice(spos,1) )
						break if !(ck > sumpix)
						spos+=1
					end
					@view_main[bl].path.value = cutstrpre + strs.slice(spos..-1)
				else
					@view_main[bl].path.value = DB.nowlist[pos].path
				end
				
				@view_main[bl].sort_weight.value = DB.nowlist[pos].sort_weight_io().floor
				
				@view_main[bl].all_time.value = DB.nowlist[pos].all_time.floor
				@view_main[bl].max_time.value = DB.nowlist[pos].max_time.floor
				@view_main[bl].exec_num.value = DB.nowlist[pos].exec_num.floor
				@view_main[bl].lasttime.value = DB.nowlist[pos].timeview(LastTime)
				@view_main[bl].oldtime.value = DB.nowlist[pos].timeview(OldTime)
				@view_main[bl].newtime.value = DB.nowlist[pos].timeview(NewTime)
				@view_main[bl].sw.set_value(DB.nowlist[pos].sw)
				@view_main[bl].button.text = pos
				
			}
			nil
		end
		
###--- 絞り込み用ウインドウ作成 destroy(デストロイ)しない			
		def fillForm(baseseet)
			subformtop = TkToplevel.new(baseseet).withdraw
			if DB::loadsubwin(DB::SUB_fillwin) != nil
				subformtop.geometry(DB::loadsubwin(DB::SUB_fillwin))
			else
				subformtop.geometry("400x200")
			end

			l_ext_list = GUISET::ListSet.new(subformtop,"絞り込み ( '|'区切りでOR、スペース区切りでAND、一致したものを上に移動)\nダブルクリックでテキストボックスにコピー",true,true)
			l_ext_list.root.pack(side:'top',anchor:'w',fill:BOTH,expand:true)

			subformtop.title("絞り込み") 
			
			hukajyouhou = /^\[(\d)+\] /

			####################
			### --- カットソート ---
			####################
			## 整理処理 koko DB.ini_data[DB::EXT_WORD][lw].ext
			seiri_proc = proc{|mode| # procを返すproc
				proc{
					if mode == "seiri1"
						[l_ext_list.list,l_ext_list.sublist1,l_ext_list.sublist2].each{|eo|
							allcutword = []
							eo.value.select{|sele| !sele.include?("cutdummy") }.each{|tmpword|
								tmpword.split("|").each{|cutwod|
									allcutword << cutwod.gsub("(","").gsub(")","").gsub("$","").clone
								}
							}
							allext = [] ; DB.ini_data[DB::EXT_WORD].each{|tob| allext += tob.ext.split("|") }
							allcutword.delete_if{|ww| allext.include?(ww) || eo.value.include?(ww) }
							allcutword.map!{|mo| mo + "|(cutdummy)" }
							eo.insert('end', *allcutword)
							tmpvalue = eo.value.uniq.clone
							eo.clear
							eo.insert('end', *tmpvalue)
						}
					elsif mode == "seiri2"
						[l_ext_list.list,l_ext_list.sublist1,l_ext_list.sublist2].each{|eo|
							chw = eo.value.clone
							chw.delete_if{|delob| delob.include?("cutdummy") }
							eo.clear
							eo.insert('end', *chw)
						}
					end # if mode == "seiri1"
				}
			}
			####################
			### --- カットソート ---
			####################
			
			##-- セーブ
			saveproc = proc{
				tmpvalue = l_ext_list.list.value.clone
				tmpvalue.map!{|objword|
					objword = objword.gsub( hukajyouhou , "" )
					objword
					}
				DB::savesubword(DB::SUB_fillwin , tmpvalue )
				DB::savesubwin( DB::SUB_fillwin , subformtop )
				# sublist1
				tmpvalue = l_ext_list.sublist1.value.clone
				tmpvalue.map!{|objword|
					objword = objword.gsub( hukajyouhou , "" ) 
					objword
					}
				DB::savesubword(DB::SUB_fillwin1 , tmpvalue )
				# sublist
				tmpvalue = l_ext_list.sublist2.value.clone
				tmpvalue.map!{|objword|
					objword = objword.gsub( hukajyouhou , "" ) 
					objword
					}
				DB::savesubword(DB::SUB_fillwin2 , tmpvalue )
			}
			subformtop.wm_protocol('WM_DELETE_WINDOW',proc{ saveproc.call ; subformtop.withdraw } )

			automake = proc{
				##-- 設定から自動作成
				temparr = []
				DB.ini_data[DB::FIND_WORD].select{|aa|
					aa[:path].size > 2 &&  aa[:ext].size > 1
				}.each{|path_kaku| # :name, :path,:ext,:incword,:noword
					inc_t = ""
					inc_t = DB.pipe_esc( path_kaku[:incword] ) if path_kaku[:incword].size > 1
					([""]+inc_t.split("|")).each{|wa|
						wa += ").*(" if wa.size > 0
						temparr << "("+path_kaku[:path][0..-1]+").*("+wa+ path_kaku[:ext]+")$"
					}
				}
				DB.ini_data[DB::EXT_WORD][0..5].select{|aa|
					aa[:path].size > 2 &&  aa[:ext].size > 1
				}.each{|path_kaku| # :name, :ext, :path)
					temparr << "("+path_kaku[:ext]+")$" 
				}
				##-- デフォルトを挿入
				l_ext_list.list.insert('end', *temparr)
				tmpvalue = l_ext_list.list.value.uniq.clone
				l_ext_list.list.clear
				l_ext_list.list.insert('end', *tmpvalue)
			}
			
			##-- load
			insword = []
			if DB::loadsubword(DB::SUB_fillwin) != nil
				insword = DB::loadsubword(DB::SUB_fillwin)
			end
			l_ext_list.list.insert('end', *insword)
			
			insword1 = []
			if DB::loadsubword(DB::SUB_fillwin1) != nil
				insword1 = DB::loadsubword(DB::SUB_fillwin1)
			end
			l_ext_list.sublist1.insert('end', *insword1)
			
			insword2 = []
			if DB::loadsubword(DB::SUB_fillwin2) != nil
				insword2 = DB::loadsubword(DB::SUB_fillwin2)
			end
			l_ext_list.sublist2.insert('end', *insword2)

			##-- 決定時の処理Proc
			okproc = proc{
						l_ext_list.bottun_add.command.call
						
						ssll = [l_ext_list.list,l_ext_list.sublist1,l_ext_list.sublist2].map{|subobj| subobj.curselection.map{|idx| subobj.value[idx] } }.flatten

						if ssll.size > 0
							karistr = ""
							notkaristr = ""
							# @match_not.value = "無視ワード"
							ssll.each{|idx|
								tempstr = idx.gsub( hukajyouhou , "" )
								if tempstr.include?("無視ワード")
									notkaristr += ( "(" + tempstr + ")|")
								else
									if !idx.include?("$")
										tempstr = DB.my_spor( tempstr )
									end
									karistr += ( "(" + tempstr + ")|")
								end
							}
							karistr.gsub!(/\|$/,"")
							notkaristr.gsub!(/\|$/,"")
							@match = Regexp.compile( DB.my_esc( karistr ), Regexp::IGNORECASE ) ## MY_ESCAPE
							@topview.variable TkVariable.new(CheckYES)
							@wordsort.value = karistr # ssll[ 0 ].gsub( hukajyouhou , "" )
							if notkaristr.size > 0
								@match_not.value = notkaristr # koko
							end
							sort_proc('path_sort')
						end
						saveproc.call
					}

			## hit数処理
			hitnum = proc{|mode| # procを返すproc
				proc{
					[ l_ext_list.list , l_ext_list.sublist1 , l_ext_list.sublist2 ].each{|listobj|
						tmpvalue = listobj.value.clone
						tmpvalue.map!{|objword|
							objword = objword.gsub( hukajyouhou , "" )
							pretext = ""
							#- hit数
							karistr = DB.my_spor( objword )
							karistr2 = Regexp.compile( DB.my_esc( karistr ), Regexp::IGNORECASE ) ## MY_ESCAPE
							fsyes = DB.nowlist.select{|obj|
								if obj.sw == "yes"
									obj.path.match( karistr2 )
								else
									false
								end
							}
							fs = DB.nowlist.select{|obj|
								if obj.sw == "yes" && obj.exec_num.floor > 0
									obj.path.match( karistr2 )
								else
									false
								end
							}
							# fs.size
							case mode
							when "hit"
								pretext = "[#{fsyes.size}] "
							when "exec_num" 
								#- 実行回数
								fitsum  = 1
								fs.each{|obj|
									fitsum += obj.exec_num.floor
								}
								pretext = "[#{fitsum}] "
							when "ave"
								#- ave表示
								fitsum  = 1
								fitexec = 1
								fs.each{|obj|
									fitsum  += obj.all_time.floor ** 0.5 
									fitexec += obj.exec_num.floor
								}
								ave = (fitsum/fitexec).round ** 2
								pretext = "[#{ave}] "
							when "alltime"
								#- 合計時間
								fitsum  = 1
								fs.each{|obj|
									fitsum  += obj.all_time.floor
								}
								pretext = "[#{fitsum}] "
							else
								pretext = ""
							end

							objword = pretext + objword
							objword
						}
						listobj.clear
						listobj.insert('end', *tmpvalue)
					}
				}
			}

			## シャッフルソート処理
			spro = proc{|w1,w2|
					w1.split("]")[0][1..-1].to_i <=> w2.split("]")[0][1..-1].to_i
			}
			shffule_proc = proc{|mode| # procを返すproc
				proc{
					[ l_ext_list.list , l_ext_list.sublist1 , l_ext_list.sublist2 ].each{|listobj|
						if listobj == nil # koko
							next
						end
						tmpvalue = listobj.value.shuffle.clone
						#- ソート
						if mode == "up"
							if tmpvalue[0].match(hukajyouhou)
								tmpvalue.sort!{|w1,w2| spro.call(w1,w2) }
							else
								tmpvalue.sort!
							end
						end
						if mode == "down"
							if tmpvalue[0].match(hukajyouhou)
								tmpvalue.sort!{|w1,w2| spro.call(w1,w2) }.reverse!
							else
								tmpvalue.sort!.reverse!
							end
						end
						listobj.clear
						listobj.insert('end', *tmpvalue)
					}
				}
			}

			
			## ボタン配置
			l1 = TkFrame.new(subformtop,borderwidth: 0,padx: -1, pady: -1).pack(side:'left')
			l4 = TkFrame.new(subformtop,borderwidth: 0,padx: -1, pady: -1).pack(side:'left')
			l2 = TkFrame.new(subformtop,borderwidth: 0,padx: -1, pady: -1).pack(side:'left')
			l3 = TkFrame.new(subformtop,borderwidth: 0,padx: -1, pady: -1).pack(side:'left')

			l5 = TkFrame.new(subformtop,borderwidth: 0,padx: -1, pady: -1).pack(side:'left') # koko

			TkButton.new(l3,padx:-1,pady:-1,text:'[数]削除').pack(side:'top').command(hitnum.call("org") )
			TkButton.new(l3,padx:-1,pady:-1,text:'シャッフル').pack(side:'top').command(shffule_proc.call("shffule") )
			TkButton.new(l2,padx:-1,pady:-1,text:'昇' ).pack(side:'top').command(shffule_proc.call("up") )
			TkButton.new(l2,padx:-1,pady:-1,text:'降' ).pack(side:'top').command(shffule_proc.call("down") )
			TkButton.new(l1,padx:-1,pady:-1,text:'hit数').pack(side:'top').command(hitnum.call("hit") )
			TkButton.new(l1,padx:-1,pady:-1,text:'総ave').pack(side:'top').command(hitnum.call("ave") )
			
			TkButton.new(l4,padx:-1,pady:-1,text:'合計時間' ).pack(side:'top').command(hitnum.call("alltime") ) # alltime exec_num
			TkButton.new(l4,padx:-1,pady:-1,text:'合計回数').pack(side:'top').command(hitnum.call("exec_num") )

			TkButton.new(l5,padx:-1,pady:-1,text:'|分割').pack(side:'top').command(seiri_proc.call("seiri1") )
			TkButton.new(l5,padx:-1,pady:-1,text:'分割削除').pack(side:'top').command(seiri_proc.call("seiri2") )

			TkButton.new(subformtop,text:'---絞り込み実行---').pack(ipadx:2,ipady:2,padx:2,pady:2,side:'left',fill:BOTH,expand:true).command(okproc)
			TkButton.new(subformtop,text:' 設定から自動作成 ').pack(ipadx:2,ipady:2,padx:2,pady:2,side:'right',fill:BOTH).command(automake)

			subformtop.deiconify()
			return subformtop # .deiconify()
			
		end # def fillForm(baseseet)
	
	end # class << self
	
end # module Seet1


module Seet2
	BOTH = 'both'
	Ne = "news"	
	Iro = '#FFFFFF'
	IroAka = DB::IRO_AKA
	
	Sunk = 'sunken' # # relief: flat (平坦)、raised (出っぱり)、sunken (引っ込み)、groove (溝)、ridge (土手) 
	Rais = 'raised'
	Groove = 'groove'	
	Norm = 'normal'
	ReOn = 'readonly'
	BoWid = 'borderwidth'
	
	Hen = '変更'	
	Sak = '削除'	
	Sarch_S = "-検索開始-"
	Sarch_E = "--検索中--"
	
	UniEntry = proc{|rr,cc|
			proc{
				relief Sunk
				borderwidth 1
				readonlybackground Iro
				grid(row: rr, column: cc ,sticky: Ne )
			}
		}
	module InSt
		def state(st)
			@selflist.each{|o| o.state(st) }
		end
	end
	class ExtStr
		include InSt
		def initialize(topform,lw,rowtop)
			rowi = lw + rowtop 
			@name = TkEntry.new(topform,width: 9, &UniEntry.call(rowi,1) )
			@ext  = TkEntry.new(topform,width:25, &UniEntry.call(rowi,2) )
			@path = TkEntry.new(topform,width:45, &UniEntry.call(rowi,3) )
			@selflist = [@name,@ext,@path]
			@edit  = TkButton.new(topform,text: Hen,width: 5, BoWid=>1, pady:-1).grid(row:rowi, column:4)
			@clean = TkButton.new(topform,text: Sak,width: 5, BoWid=>1, pady:-1).grid(row:rowi, column:5)
		end
		attr_accessor :name,:ext,:ext,:path,:edit,:clean
	end
	class FindSet
		include InSt
		def initialize(topform,lw,rowtop)
			rowi = lw + rowtop
			@name    = TkEntry.new(topform,width:  9, &UniEntry.call(rowi,1) )
			@path    = TkEntry.new(topform,width: 30, &UniEntry.call(rowi,2) )
			@ext     = TkEntry.new(topform,width: 15, &UniEntry.call(rowi,3) )
			@incword = TkEntry.new(topform,width: 15, &UniEntry.call(rowi,4) )
			@noword  = TkEntry.new(topform,width: 15, &UniEntry.call(rowi,5) )
			@selflist = [@name,@path,@ext,@incword,@noword]
			@edit  = TkButton.new(topform, text: Hen, width: 5, borderwidth: 1, pady: -1).grid(row:rowi, column:6)
			@clean = TkButton.new(topform, text: Sak, width: 5, borderwidth: 1, pady: -1).grid(row:rowi, column:7)
		end
		attr_accessor :name,:path,:ext,:incword,:noword,:edit,:clean,:selflist
	end

	def self.SubForm(baseseet,num,dbWORD)
			# dbWORD = DB::FIND_WORD || DB::EXT_WORD
			subformtop = TkToplevel.new(baseseet).withdraw
			subformtop.title(dbWORD)
			
		if dbWORD == DB::EXT_WORD
			if DB::loadsubwin(DB::SUB_set_ext) != nil
				subformtop.geometry( DB::loadsubwin(DB::SUB_set_ext) )
			end
		elsif dbWORD == DB::FIND_WORD
			if DB::loadsubwin(DB::SUB_set_find) != nil
				subformtop.geometry( DB::loadsubwin(DB::SUB_set_find) )
			end
		end
			
			##--- main fream
			name_frame = TkFrame.new(subformtop,relief: Groove,borderwidth: 1,padx: 1, pady: 1).pack(side:'top',anchor:'w',fill:'x')
			ext_fram   = TkFrame.new(subformtop,relief: Groove,borderwidth: 2,padx: 4, pady: 4).pack(side:'top',anchor:'w',fill:BOTH,expand:true)
			path_fream = TkFrame.new(subformtop,relief: Groove,borderwidth: 2,padx: 4, pady: 4).pack(side:'top',fill:'x')
			last_fram  = TkFrame.new(subformtop,padx: 5, pady: 5).pack(side:'top')
			
			##--- fream 1 name_frame
			TkLabel.new(name_frame, text: "セット名").pack(side:'left',anchor:'w')
			l_namebox = TkEntry.new(name_frame,relief: Sunk, width: 20).pack(side:'left',fill:BOTH)
			
			##--- fream 2 ext_fram
			l_ext_list = GUISET::ListSet.new(ext_fram,"拡張子")
			l_ext_list.root.pack(side:'left',anchor:'w',fill:BOTH)
		if dbWORD == DB::FIND_WORD
			l_incword  = GUISET::ListSet.new(ext_fram,"絞り込み文字（サブDirなど）")
			l_noword   = GUISET::ListSet.new(ext_fram,"無視文字")
			l_incword.root.pack(side:'left',anchor:'w',fill:BOTH,expand:true)
			l_noword.root.pack(side:'left',anchor:'w',fill:BOTH,expand:true)
		end
			
			##--- fream 3 path_fream
			l_pathbox = TkEntry.new(path_fream, relief: Sunk , width: 50).pack(side:'top',fill:'x')
		if dbWORD == DB::FIND_WORD
			pathselect = Proc.new{
				l_pathbox.value = GUISET.ChooseDirectory(l_pathbox,l_pathbox.value)
				l_namebox.focus
				subformtop.set_grab
				}
			choosebutton = TkButton.new(path_fream,text:'検索Dirの設定',command: pathselect ).pack(ipadx:2,ipady:2,padx:2,pady:2,side:'right')
		elsif dbWORD == DB::EXT_WORD
			pathselect = Proc.new{
				l_pathbox.value = Tk.getOpenFile(title: 'プログラムを設定',filetypes: "{実行ファイル {.exe}} {全てのファイル {.*}}")
				l_namebox.focus
				subformtop.set_grab
			}
			TkButton.new(path_fream,text:'実行pathの設定',command: pathselect ).pack(ipadx:2,ipady:2,padx:2,pady:2,side:'right',anchor:'e')
			systemselect = Proc.new{ l_pathbox.value = "system() # 直接実行、もしくは関連付けのプログラムで実行"}
			TkButton.new(path_fream,text:'直接実行、関連付け実行',command: systemselect ).pack(ipadx:2,ipady:2,padx:2,pady:2,side:'right',anchor:'e')
		end
		
			##--- fream 4 last_fram
			okproc = Proc.new{|num| # OK時にDBを更新
				dbalias = DB.ini_data[dbWORD][num]
		if dbWORD == DB::FIND_WORD
				dbalias.incword = l_incword.list.value.join("|")
				dbalias.noword  = l_noword.list.value.join("|")
		end
				dbalias.ext  = l_ext_list.list.value.join("|")
				dbalias.name = l_namebox.value
				dbalias.path = l_pathbox.value
				Seet2.ini_view()
			}
			
			winsaveproc = proc{
		if dbWORD == DB::EXT_WORD
				DB::savesubwin(DB::SUB_set_ext,subformtop)
		elsif dbWORD == DB::FIND_WORD
				DB::savesubwin(DB::SUB_set_find,subformtop)
		end
			}
			TkButton.new(last_fram,text:'ok', width:10 , 
					command: proc{okproc.call(num); winsaveproc.call();subformtop.destroy} ).pack(ipadx:2,ipady:2,padx:2,pady:2,side:'left')
			TkButton.new(last_fram,text:'cancel', width:10 , 
					command: proc{                  winsaveproc.call();subformtop.destroy} ).pack(ipadx:2,ipady:2,padx:2,pady:2,side:'left')
			subformtop.wm_protocol('WM_DELETE_WINDOW',proc{ winsaveproc.call();subformtop.destroy} )
			# view set
			findset = DB.ini_data[dbWORD][num]
			l_ext_list.list.insert('end', *findset.ext.split("|"))
		if dbWORD == DB::FIND_WORD
			l_incword.list.insert( 'end', *findset.incword.split("|"))
			l_noword.list.insert(  'end', *findset.noword.split("|"))
		end
			l_namebox.value = findset.name
			l_pathbox.value = findset.path
			
			# wait
			subformtop.deiconify()
			l_namebox.focus
			subformtop.set_grab
			subformtop.wait_destroy()
			subformtop.release_grab
			
			nil
	end # def SubForm(baseseet,num,dbWORD)

	@ini_ext = []
	@ini_find = []
	@kanri = nil

	class << self
	
		def make(seet2)

			###--- save load button -------------------  
			saveload_frame = TkFrame.new(seet2).pack(side:'top',padx:5,pady:5,ipadx:5,ipady:5 ,anchor:'w')
			saveloadproc = proc{
				DB.setini_read_and_wite();
				@kanri.set(DB.ini_data[DB::FIND_WORD].size);
				Seet2.ini_view()
			}
			TkButton.new(saveload_frame,text: "ロード", width: 10, command: saveloadproc ).pack(side:'left',padx:5)
			TkButton.new(saveload_frame,text: "セーブ", width: 10, command: saveloadproc ).pack(side:'left',padx:5)

			#--- 個数変更 ---
			TkFrame.new(saveload_frame){|mf|
				relief Sunk
				borderwidth 1
				pack(side:'left',padx:5)
				TkLabel.new(mf,font:{size:8}).pack(side:'left').text("ﾒｲﾝﾘｽﾄ表示数\n要再起動")
				listline = DB.main_list_view_num()
				mainlistnum = TkSpinbox.new(mf,to: 50 ,from: 10 ,increment:1,width:3).pack(side:'left',fill:BOTH)
				mainlistnum.set(listline)
				mainlistnum.command( proc{ DB.main_list_view_num( mainlistnum.get.to_i ) } )
			}
			#--- 未実行の最終実行日時の設定 ---
			TkFrame.new(saveload_frame){|mf|
				relief Sunk
				borderwidth 1
				pack(side:'left',padx:5)
				TkLabel.new(mf,font:{size:8}).pack(side:'left').text("未実行のファイルの\n最終実行日時の設定")
				TkLabel.new(mf              ).pack(side:'left').text("検索日時から")
				listline = DB.not_exec_find_exectime()
				tmpfindexec = TkSpinbox.new(mf,to: 1000 ,from: -1000 ,increment:1,width:5).pack(side:'left',fill:BOTH)
				TkLabel.new(mf              ).pack(side:'left').text("日")
				tmpfindexec.set(listline)
				tmpfindexec.command( proc{ DB.not_exec_find_exectime( tmpfindexec.get.to_i ) } )
			}
; logging( TC.setget( __FILE__ , __LINE__  ) , "seet2_1" ) ;

			###--ステータスバー
			stview = TkLabel.new(seet2){
				relief Groove
				borderwidth 3
				width 99
				pack(side:'top',fill:'x')
				justify 'left'
				anchor 'w'
				}.text("------------------------")

###--- 検索設定 -------------------
			set_find = TkFrame.new(seet2, relief: Groove, borderwidth: 3).pack(side:'top',padx:5,pady:5,ipadx:5,ipady:5 ,fill:'x')
				#-- 1行目 設定題名
				TkLabel.new(set_find, text: DB::FIND_WORD, borderwidth: 0).grid(row:1,column:1,sticky: "w")
				#- 操作フレーム　
				set2_fream = TkFrame.new(set_find, relief: 'raised', borderwidth: 1).grid(row:1,column:2,columnspan:6,sticky: Ne)
					#-- 管理数
					TkLabel.new(set2_fream, text: '管理セット数' ).pack(side:'left', anchor:'w',fill:BOTH)
					@kanri = TkSpinbox.new(set2_fream,to:100,from:6,increment:1,width:5).pack(side:'left', anchor:'w',fill:BOTH)
					@kanri.command( proc{Seet2.ini_view()} )
					@kanri.set(DB.ini_data[DB::FIND_WORD].size)
					#-- 条件ソート
					findsort = TkButton.new(set2_fream ,
								text:"検索Dirでソート",
								borderwidth: 4).pack(ipadx:1,ipady:1,padx:1,pady:1,side:'left', anchor:'w',fill:'y')
					findsort.command proc { 
								DB.ini_data[DB::FIND_WORD].sort!{|ob1,ob2|
										if ob1.path == ""
											1
										elsif ob2.path == ""
											-1
										else
											ob1.path<=>ob2.path
										end
										}
								Seet2.ini_view()
								}
					#-- 検索ボタン
					findbuton = TkButton.new(set2_fream ,
								text:Sarch_S,
								borderwidth: 4).pack(ipadx:1,ipady:1,padx:1,pady:1,side:'left', anchor:'w',fill:'y')
					findupdateproc =  proc{
						stlbk = stview.background
						stview.background '#00FFFF'
						findbuton.text = Sarch_E ; 
						bkup = findbuton.background
						findbuton.background IroAka ; 
						$root.update
						DB.findcheck(stview)
						findbuton.text = Sarch_S ; 
						findbuton.background bkup ; 
						stview.background stlbk
						$root.update
					}
					findbuton.command(findupdateproc)
					
					TkLabel.new(set2_fream,
							text: "検索Dirで指定した【拡張子】のファイルをさがします。「絞り込み」「無視文字」指定した場合\nフルパスに【絞り込みのどれかを含み】かつ【無視文字のどれも含まない】ものが対象" ,
							justify:'left' ).pack(side:'left', anchor:'w')
				#-- 2行目 変数名前
				coli = 1
				rowi = 2
				[ "セット名" , "検索Dir(必須)" , "拡張子(必須)" , "絞り込み（サブDirなど）" , "無視文字" ].each{|ww|
					TkLabel.new(set_find, text: ww ).grid(row:rowi, column:coli,sticky: Ne )
					coli += 1
				}
				###---view seet1 疑似スクロールバー--------------------
				@mvscroll = GUISET::MvScroll.new(set_find)
				@mvscroll.root.grid(row:2, column:100,rowspan:100,sticky: Ne)
				@mvscroll.command( proc{ Seet2.ini_view() } )
				#-- 3行目以降
				1.upto(5){|lw|
					@ini_find << FindSet.new(set_find,lw,2)
					@ini_find[-1].edit.command{ Seet2.SubForm(set_find,lw-1+@mvscroll.nowpos,DB::FIND_WORD) }
					@ini_find[-1].clean.command{ Seet2.clean(DB.ini_data[DB::FIND_WORD][lw-1+@mvscroll.nowpos]) }
					@ini_find[-1].selflist.each{|obj|
						@mvscroll.set_Mouse_wheel( obj ,1) # マウスホイールのスクロール設定
					}
				}
				set_find.grid_columnconfigure(2,weight: 2)
				set_find.grid_columnconfigure(3,weight: 2)
				set_find.grid_columnconfigure(4,weight: 2)
				set_find.grid_columnconfigure(5,weight: 2)

; logging( TC.setget( __FILE__ , __LINE__  ) , "seet2_2" ) ;

###--- 拡張子別実行プログラム設定 -------------------
			fsub=TkFrame.new(seet2).pack(side:'top',fill:'x',expand:true)
				extfr = TkFrame.new(fsub, relief: Groove, borderwidth: 3 ).pack(side:'left',anchor:'n',padx:5,pady:5,ipadx:5,ipady:5 ,fill:'x',expand:true)
				#-- 1行目 設定題名
				TkLabel.new(extfr,text: DB::EXT_WORD, borderwidth: 0).grid(row:1,column:1,columnspan: 2,sticky: "w")
				#-- 2行目 変数名前
				coli = 1
				rowi = 2
				[ "セット名" , "拡張子" , "実行プログラム" ].each{|ww|
					TkLabel.new(extfr, text: ww ).grid(row:rowi, column:coli,sticky: Ne )
					coli += 1
				}
				#-- 3行目以降
				1.upto(6){|lw|
					@ini_ext << ExtStr.new(extfr,lw,2)
					@ini_ext[-1].edit.command{ Seet2.SubForm(extfr,lw-1,DB::EXT_WORD) }
					@ini_ext[-1].clean.command{ Seet2.clean(DB.ini_data[DB::EXT_WORD][lw-1]) }
				}
				extfr.grid_columnconfigure(2,weight: 1)
				extfr.grid_columnconfigure(3,weight: 1)

; logging( TC.setget( __FILE__ , __LINE__  ) , "seet2_3" ) ;

###--- ソート設定 -------------------
				set_sortnum  = TkFrame.new(fsub, relief: Groove, borderwidth: 3 ).pack(side:'right',padx:5,pady:5,ipadx:5,ipady:5 )
				rowi = 1
				TkLabel.new(set_sortnum,text:DB::SUB_SORT_SET).grid(row:rowi,column:1,columnspan:2)
				TkLabel.new(set_sortnum,font:{size:8},text:"※ソート順\n２次ソート優先度\n(10以下無効)").grid(row:rowi,column:3,columnspan:2)
				rowi = 2
				TkLabel.new(set_sortnum,text:"key"   ).grid(row:rowi,column:1)
				TkLabel.new(set_sortnum,text:"各ソート順").grid(row:rowi,column:2,columnspan:2)
				TkLabel.new(set_sortnum,text:"優先度").grid(row:rowi,column:4,columnspan:2)
				@subsortobj = []
				DB.ini_data[DB::SUB_SORT_SET].each_index{|yn|
					mn = DB.ini_data[DB::SUB_SORT_SET][yn]
					ypos = 3 + yn
					seto = DB::SubFind.new(\
						TkLabel.new(set_sortnum,borderwidth:1,relief:Sunk,text:mn[:key],pady:-1).grid(column:1,row:ypos),\
						TkVariable.new(mn[:value]),\
						TkEntry.new(set_sortnum,width:5).grid(column:4,row:ypos)\
					)
					seto[:value].trace("w", proc{ DB.ini_data[DB::SUB_SORT_SET][yn][:value] = @subsortobj[yn][:value].value.to_i } )
					seto[:weight].value = mn[:weight]
					seto[:weight].bind('KeyRelease',proc{ DB.ini_data[DB::SUB_SORT_SET][yn][:weight] = @subsortobj[yn][:weight].value.to_i })
					rb1 = TkRadioButton.new(set_sortnum,text:'降順',value: 1,variable: seto[:value],padx:-1,pady:-1).grid(column:2,row:ypos)
					rb2 = TkRadioButton.new(set_sortnum,text:'昇順',value:-1,variable: seto[:value],padx:-1,pady:-1).grid(column:3,row:ypos)
					#if mn[:value] == 0
					#	rb1.state('disabled')
					#	rb2.state('disabled') # 'normal'
					#end
					@subsortobj << seto
				}
				
			###---
			return seet2

		end # def make(seet2)

		def clean(ext_set)
				ext_set.members.each{|o| ext_set[o] = "" if o != :name }
				Seet2.ini_view()
		end

		def ini_view() # 設定画面再描画
			DB.ini_data[DB::SUB_SORT_SET].sort!{|aa,bb|
					( (bb[:weight]<=>aa[:weight]) == 0 ) ? bb[:key]<=>aa[:key] : bb[:weight]<=>aa[:weight]
					}
			DB.ini_data[DB::SUB_SORT_SET].each_index{|yn| 
				@subsortobj[yn][:key].text = DB.ini_data[DB::SUB_SORT_SET][yn][:key]
				@subsortobj[yn][:value].value = DB.ini_data[DB::SUB_SORT_SET][yn][:value]
				@subsortobj[yn][:weight].value = DB.ini_data[DB::SUB_SORT_SET][yn][:weight]
			}
				
			@ini_ext.each_index{|lw|
				@ini_ext[lw].state(Norm)
				@ini_ext[lw].name.value = DB.ini_data[DB::EXT_WORD][lw].name
				@ini_ext[lw].ext.value  = DB.ini_data[DB::EXT_WORD][lw].ext
				@ini_ext[lw].path.value = DB.ini_data[DB::EXT_WORD][lw].path
				@ini_ext[lw].state(ReOn)
			}
			
			find_orgsize = DB.ini_data[DB::FIND_WORD].size
			find_newsize = @kanri.get.to_i
			if find_orgsize < find_newsize
				find_orgsize.upto(find_newsize){|nn|
					DB.ini_data[DB::FIND_WORD] << DB::FindSet.new("#{nn+1}","","","","")
				}
			elsif find_orgsize > find_newsize
				DB.ini_data[DB::FIND_WORD].slice!(find_newsize..-1)
			end
			@mvscroll.basepos( DB.ini_data[DB::FIND_WORD].size , @ini_find.size )
			@ini_find.each_index{|lw|
				pos = @mvscroll.nowpos + lw
				@ini_find[lw].state(Norm)
				@ini_find[lw].name.value    = DB.ini_data[DB::FIND_WORD][pos].name
				@ini_find[lw].path.value    = DB.ini_data[DB::FIND_WORD][pos].path
				@ini_find[lw].ext.value     = DB.ini_data[DB::FIND_WORD][pos].ext
				@ini_find[lw].incword.value = DB.ini_data[DB::FIND_WORD][pos].incword
				@ini_find[lw].noword.value  = DB.ini_data[DB::FIND_WORD][pos].noword
				@ini_find[lw].state(ReOn)
			}
		end # def ini_view()
		
	end # class << self
	
end # module Seet2


module Seet3
	class << self
		def make(seet3)
str1 = <<-EOS
【メイン】
・上段左から
	・無効を非表示中＜＝＞無効を表示中
			クリックで切り替え
	・絞り込みウィンドウ　ファイルの検索用ウインドウ表示
			指定したワードを含むファイルを上部に持ってきます（上半分TOP固定の機能はこのため）
			登録したワードは自動セーブされます
	・逆順ソート　起動時チェック無し
			チェックを付けるとソート順が逆になります
	・直近無視　起動時チェック無し
			チェックが付いていると　日付並替で指定している時間以内に実行したものを
			ソート時一番下に移動します
	・並べ替え乱数　デフォルト50 自動セーブされます
			数値ソートするとき差が±指定％以内の場合　シャッフル判定
			シャッフル判定の場合 2次ソートの優先度の高いほうからソートします。
			最後までシャッフル判定だった場合はシャッフルしますキッチリソートしたいなら0を指定
			この数値はファイル名並べ替えにも効いてきます
	・日付並替乱数　デフォルト72 自動セーブされます
			日付をソートするとき差が±指定時間以内の場合　シャッフル判定
			シャッフル判定の場合 2次ソートの優先度の高いほうからソートします。
			最後までシャッフル判定だった場合はシャッフルしますキッチリソートしたいなら0を指定
	・上半分TOP固定　起動時チェック有り
			チェックが付いていると　リストの上半分が0番からになり
			スクロールされるのが下半分だけになります（絞り込み時自動チェック）
	・検索ワードボックス　
			絞り込みたいワードを入力してエンター
			無視ワードも指定可能
	・表示中からランダム実行する　表示中のものからランダムに選択して実行します。
		連続実行中にもう一度押すと、連続実行を中断して、現在実行中の終了待ちへ
	・連続実行回数　デフォルト３　連続実行する際の個数です
		ランダム実行回数のラベルをクリックすると連続実行に切り替えられます
	・平均時間ソートボタン　実行の平均時間でソート
	・作成日更新日の表示非表示ボタン
		FILEの作成日や更新日の項目を表示したり非表示にしたり
		
・下段左上から
	・番号ボタンの挙動 『実行する』＜＝＞『Fileの場所を開く』
		クリックで切り替え
	・有効無効　有効無効でソート
		チェックを外すとそのファイルは実行無視、非表示となります。
		修正したい場合は「無効を表示中」に切り替えチェックを付けてください
	各項目ボタン　各項目でソート
	
EOS
str = <<-EOS
【ワード検索仕様】
	[漫画 zip] スペース刻みでAND検索（順番も見ます "H漫画.zip"は対象 "zip漫画.pdf" は非対象 ）
	[漫画|zip] |刻みでor検索（順番は関係なし "H漫画.zip"、"zip漫画.pdf" どちらも対象 ）
	[(H zip)|(H pdf)] ()カッコで検索条件をグループ化 ）
【設定】
	検索開始ボタンで
	ファイルの新規検出と
	ファイルの移動削除検出をします
【自動ソート設定】
	各ソート順　各条件の向きの設定
	2次ソート優先度 ボタンでソートしたときシャッフル判定になると
	優先度の高いほうでソート
	【直前のソート】は文字どおり1回前のソート条件
	【ワード検索】は直前の検索ワードに一致するファイルを優先

【その他】
●作成されるファイル
	"._reportlog.txt" 動作ログ
	"listapp_setting.yml" 設定の保存
	"listapp_list.bin" 「管理ファイルリスト」バイナリ版（読み込み時こちらを優先）
	"listapp_list.txt" 「管理ファイルリスト」テキスト版（バイナリ版が無いときこちらを読み込み）
	"listapp_list.txt_bkup.txt" 1回前の「管理ファイルリスト」のバックアップ
	"listapp_list.txt[日付]" 「管理ファイルリスト」のサイズが小さくなる前のバックアップ
	"listapp_list.txt_DEL_bkup.txt" 削除されたデータの保存
	
●「管理ファイルリスト」の保存タイミング(バイナリ版、テキスト版両方)
	・連続実行終了時（起動中のものを閉じた後）
	・検索終了時
	・右上×で終了するとき
	
●「管理ファイルリスト」の自動バックアップ（テキスト版のみ)
	・前回のデータを"_bkup.txt"を付けて保存
	・サイズが小さくなった場合小さくなる前のものを[日付]を付けて保存
	
●管理しているファイルを移動、リネームした場合の自動認識機能について
	設定している検索Dir内で移動やリネームをした場合は
	再度検索することで、ファイルのサイズや名前、更新作成日付、入っているディレクトリ名から
	移動先を検出して、それまでのデータ（実行時間や実行回数）を移行します
	移動先が検出できなかったデータは_DEL_bkup.txtに保存され、
	次回検索時に再チェックされます。
	復旧の見込みがないファイルのデータを削除したい場合は手作業でお願いいたします

EOS
			TkLabel.new(seet3,justify:'left', anchor:'w',background:'#FFFFFF',
				text:str1.gsub("	","   ")).pack(side:'left', anchor:'w',fill:'both')
			TkLabel.new(seet3,justify:'left', anchor:'w',background:'#FFFFFF',
				text:str.gsub("	","   ")).pack(side:'left', anchor:'w',fill:'both')

		end
	end
end

REPORT_LOG = "._reportlog.txt"
$log = nil
def logging(*str)
	$log.print str
	$log.print "\n"
end

begin

File.open(".lock","w"){|ff|
locked = ff.flock(File::LOCK_EX | File::LOCK_NB)
if !locked
	subformtop = TkRoot.new
	subformtop.title("多重起動禁止")
	TkLabel.new(subformtop,text:"\n多重起動禁止\n------すでに起動中です---------------------\n").pack(ipadx:5,ipady:5,padx:5,pady:5,side:'top')
	subformtop.deiconify()
	subformtop.wait_destroy()
else

	#-- レポートログ
	oldlog = [nil,nil]
	oldlog = File.read(REPORT_LOG).split("\n") if File.exist?(REPORT_LOG)
	$log = File.open(REPORT_LOG , "w" )
	$log.puts "-----"
	$log.puts oldlog[oldlog.size/3..-1]
	$log.puts "-----"
	$log.print  "\n", RUBY_VERSION , " ",Time.new

	#-- DB 初期化
	DB.new() ; logging( TC.setget( __FILE__ , __LINE__  ) , "yomi" ) ; 
	winpos = DB.ini_data["window"]

	###---root-------------------
	$root = TkRoot.new{
		if winpos != nil
			geometry "#{winpos[:geometry]}"
			#geometry "+#{winpos[:xx]}+#{winpos[:yy]}"
			#width winpos[:width]
		else
			geometry "+100+10"
		end
		wm_protocol('WM_DELETE_WINDOW',# windowの右上　xボタンが押されたとき設定
			proc{
				DB.setini_winonly_wite()
				res = DB.setini_read_and_wite()
				return if res == "skip"
				DB.list_remake()
				$root.destroy
			}
		)
	}
	#Tk.root.width( winpos[:width] ) if winpos != nil

	TkOptionDB.add('*font', "\"MS UI Gothic\" 10")

	seet1 = nil
	seet2 = nil
	seet3 = nil

=begin
		# Tk::Tile::Notebook を使うより、Frameとボタンで自作したほうがロードがはやい
		tabroot = Tk::Tile::Notebook.new($root){|bf|
			###---TabSeet--------------------
			seet1 = TkFrame.new(bf).bind('Map', proc{ Seet1.review()  } )
			seet2 = TkFrame.new(bf).bind('Map', proc{ Seet2.ini_view() } )
			seet3 = TkFrame.new(bf)
			bf.add( seet1, text:'メインリスト' )
			bf.add( seet2, text:'---設定---' )
			bf.add( seet3, text:'---解説---' )
			pack(fill:'both',expand:true)
		}
=end

###--- Notebook の代替え　ここから
	IROsiro = '#FFFFFF'
	IROhai = '#888888'
	tab_setlist = []#-- 各frame 格納リスト
	tab_btnlist = []#-- 切り替え用ボタン格納リスト
	nowseet = 0
	##-- 切り替え用ボタン配置frame
		chp = proc{|nn| #-- 切り替え用関数
			proc{
					tab_setlist[nowseet].unpack
					tab_btnlist[nowseet].background IROhai
					tab_setlist[nn].pack( fill:'both')
					#tab_setlist[nn].pack( fill:'both',expand:true)
					tab_btnlist[nn].background IROsiro
					nowseet = nn
			}
		}
	TkFrame.new($root){|bf|
		#-- 切り替え用ボタン
		tab_btnlist << TkLabel.new(bf){ text 'メインリスト'
			background IROsiro
			bind('Button-1',chp.call(0))
			pack(side:'left')
		}
		tab_btnlist << TkLabel.new(bf){ text '---設定---'
			background IROhai
			bind('Button-1',chp.call(1))
			pack(side:'left')
		}
		tab_btnlist << TkLabel.new(bf){ text '---解説---'
			background IROhai
			bind('Button-1',chp.call(2))
			pack(side:'left')
		}
		pack(side:'top' , fill:'both')
		TkLabel.new(bf){ text 'Ctrl+C:コピー、Ctr+V:ペースト が使えます'
			pack(side:'right')
		}
	}
	##-- 切り替え表示frame
	TkFrame.new($root){|bf|
		tab_setlist << seet1 = TkFrame.new(bf).pack( fill:'both').bind('Map', proc{ Seet1.review()  } )
		tab_setlist << seet2 = TkFrame.new(bf).bind('Map', proc{ Seet2.ini_view() } )
		tab_setlist << seet3 = TkFrame.new(bf).bind('Map', proc{  } )
		pack(side:'top' , fill:'both', expand:true )
	}
###--- Notebook の代替え　ここまで

 ; logging( TC.setget( __FILE__ , __LINE__  ) , "root" ) ; 
 
	#--- Seet 作成
	Seet1.make(seet1) ; logging( TC.setget( __FILE__ , __LINE__  ) , "seet1" ) ; 
	Seet2.make(seet2) ; logging( TC.setget( __FILE__ , __LINE__  ) , "seet2" ) ; 
	Seet3.make(seet3) ; logging( TC.setget( __FILE__ , __LINE__  ) , "seet3" ) ; 

	#-- 初期設定警告
	if DB.nowlist.size < 2
		chp.call(1).call()
		GUISET.FarstSet($root)
	end
	
	#-- 初期検索
	#if false
	#	chp.call(1).call()
	#end
	#-- タイトルにロード時間表示
	$root.title = "Window Rubyver=#{RUBY_VERSION} loadtime=#{Time.now - time_start}" 
	$startupdir = Dir.pwd + "/"
	Tk.mainloop
	
	$log.close
	
end # !locked
} # ロック

rescue=>e

	 print "異常終了しましたこのエラーメッセージを製作者に報告してください。\n"
	 p e.class
	 p e.message
	 p e.backtrace
	$log.close
	 gets
	 
end

