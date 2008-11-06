<?php
//*******************************************
// Silverhold Stat parser
// Written by Adam Laycock (Arcath)
//*******************************************

class db{
	function connect($host,$user,$pass,$db){
		mysql_connect($host,$user,$pass);
		mysql_select_db($db);
		return true;
	}
	function query($q){
		return mysql_query($q);
	}
}

class stats{
	public $hist=100, $nicks=array(), $counts=array(), $db, $alias=array(), $regex=array(), $system=array(), $gs=array();
	function build(){
		$this->db=new db;
		$this->db->connect('localhost','bot','dyton','bot');
		$this->aliasbuild();
		$this->zerocounts();
		$res=$this->db->query("SELECT * FROM `system`");
		while($row=mysql_fetch_array($res)){
			$this->system[$row['field']]=$row['value'];
		}
		$res=$this->db->query("SELECT * FROM `log`");
		while($row=mysql_fetch_array($res)){
			$nick=$this->getnick($row['nick']);
			if($nick!="NORECORD"){
				$hour=date("G",$row['time']);
				$this->gs['total']+=1;
				$this->gs[$hour]+=1;
				$this->counts[$nick]['lines']+=1;
				$words=str_word_count($row['s']);
				$this->counts[$nick]['words']+=$words;
				$chars=strlen($row['s']);
				$this->counts[$nick]['chars']+=$chars;
				foreach($this->regex as $key => $string){
					if(preg_match($string,$row['s'])==1){
						$this->counts[$nick][$key]+=1;
					}
				}
			}
		}
	}
	function aliasbuild(){
		$res=$this->db->query("SELECT * FROM `smarts` where `item` = 'alias'");
		$aliases=array();
		$total=0-1;
		while($row=mysql_fetch_array($res)){
			$dot=strpos($row['fact'],".");
			$alias=substr($row['fact'],$dot+1);
			$temp=explode(".",$row['fact']);
			$nick=$temp[0];
			if(isset($aliases[$nick]['count'])){
				$aliases[$nick]['count']+=1;
			}else{
				$aliases[$nick]['count']=1;
				$total+=1;
				$this->nicks[]=$nick;
			}
			$aliases[$nick][$aliases[$nick]['count']]=$alias;
		}
		for($i=0;$i<=$total;$i++){
			for($j=1;$j<=$aliases[$this->nicks[$i]]['count'];$j++){
				if($j==1){
					$aliases[$this->nicks[$i]]['string']="/(";
				}
				$aliases[$this->nicks[$i]]['string'].=$aliases[$this->nicks[$i]][$j];
				if($j==$aliases[$this->nicks[$i]]['count']){
					$aliases[$this->nicks[$i]]['string'].=")/";
				}else{
					$aliases[$this->nicks[$i]]['string'].="|";
				}
			}
			$this->alias[$this->nicks[$i]]=$aliases[$this->nicks[$i]]['string'];
		}
	}
	function getnick($in){
		foreach($this->alias as $nick => $string){
			if(preg_match($string,$in)==1){
				$out=$nick;
			}
		}
		if(!isset($out)){
			$out="NORECORD";
		}
		return $out;
	}
	function zerocounts(){
		$res=$this->db->query("SELECT * FROM `smarts` WHERE `item` = 'regex'");
		while($row=mysql_fetch_array($res)){
			$dot=strpos($row['fact'],".");
			$regex=substr($row['fact'],$dot+1);
			$temp=explode(".",$row['fact']);
			$key=$temp[0];
			$this->regex[$key]=$regex;
		}
		for($i=0;$i<=23;$i++){
			$this->gs[$i]=0;
		}
		$this->gs['total']=0;
		foreach($this->nicks as $key => $nick){
			$this->counts[$nick]['lines']=0;
			$this->counts[$nick]['words']=0;
			$this->counts[$nick]['chars']=0;
			foreach($this->regex as $reg=> $s){
				$this->counts[$nick][$reg]=0;
			}
		}
	}
	function toptable(){
		$temp1=array();
		$temp2=array();
		$out="<table border=\"0\" cellspacing=\"0\" cellpadding=\"0\" width=\"100%\">
			<tr>
			<td>Rank</td>
			<td>Nick</td>
			<td>Lines</td>
			<td>Words</td>
			<td>WPL</td>
			<td>Charcters</td>
			</tr>";
		foreach($this->nicks as $i => $nick){
			$temp1[]=$nick;
			$temp2[]=$this->counts[$nick]['lines'];
		}
		arsort($temp2);
		$rank=1;
		foreach($temp2 as $i => $count){
			$wpl=$this->counts[$temp1[$i]]['words']/$count;
			$wpl=number_format($wpl,2);
			$count=number_format($count);
			$words=number_format($this->counts[$temp1[$i]]['words']);
			$chars=number_format($this->counts[$temp1[$i]]['chars']);
			$out.="<tr>
			<td>$rank</td>
			<td>{$temp1[$i]}</td>
			<td>{$count}</td>
			<td>{$words}</td>
			<td>$wpl</td>
			<td>$chars</td>
			</tr>";
			$rank+=1;
		}
		$out.="</table>";
		return $out;
	}
	function regextable(){
		$out="";
		foreach($this->regex as $key => $reg){
			$most=$this->most($key);
			$out.="Most {$key} where said by {$most}<br />";
		}
		return $out;
	}
	function most($key){
		$temp1=array();
		$temp2=array();
		foreach($this->nicks as $i => $nick){
			$temp1[]=$nick;
			$temp2[]=$this->counts[$nick][$key];
		}
		arsort($temp2);
		foreach($temp2 as $i => $count){
			if(!isset($out)){ $out=$temp1[$i]; }
		}
		return $out;
	}
	function timeofday(){
		$out="<table border=\"0\" cellspacing=\"0\" cellpadding=\"0\" width=\"100%\"><tr>";
		for($i=0;$i<=23;$i++){
			$per[$i]=number_format(($this->gs[$i]/$this->gs['total'])*100,2);
			$h=intval($per[$i]*10);
			if($i>=0 && $i<=5){
				$col="blue";
			}elseif($i>=6 && $i<=11){
				$col="green";
			}elseif($i>=12 && $i<=17){
				$col="yellow";
			}elseif($i>=18 && $i<=23){
				$col="red";
			}
			$out.="<td valign=\"bottom\" align=\"center\"><img src=\"$col-v.png\" width=\"15\" height=\"$h\" /><br />{$per[$i]}%</td>";
		}
		$out.="</tr><tr>";
		for($i=0;$i<=23;$i++){
			$out.="<td align=\"center\">$i</td>";
		}
		return $out;
	}
}
$stats=new stats;
$stats->build();
echo("<html>
	<head>
	<title>{$stats->system['chan']} stats by {$stats->system['name']}</title>
	<style>
	body{
		background-color:#000000;
		color:#FFFFFF;
		font-family: Arial, sans-serif;
	}
	</style>
	</head>
	<body>
	<h1>{$stats->system['chan']} Stats by {$stats->system['name']}</h1>
	{$stats->timeofday()}<br />{$stats->toptable()}<br />{$stats->regextable()}
	</body>
	</html>");
?>
