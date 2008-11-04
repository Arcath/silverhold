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
	public $hist=100, $nicks=array(), $counts=array(), $db, $alias=array(), $regex=array(), $system=array();
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
				$this->counts[$nick]['lines']+=1;
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
		foreach($this->nicks as $key => $nick){
			$this->counts[$nick]['lines']=0;
			foreach($this->regex as $reg=> $s){
				$this->counts[$nick][$reg]=0;
			}
		}
	}
	function toptable(){
		$temp1=array();
		$temp2=array();
		$out="";
		foreach($this->nicks as $i => $nick){
			$temp1[]=$nick;
			$temp2[]=$this->counts[$nick]['lines'];
		}
		arsort($temp2);
		foreach($temp2 as $i => $count){
			$out.="{$temp1[$i]} Has {$count} Lines<br />";
		}
		return $out;
	}
}
$stats=new stats;
$stats->build();
echo("<html>
	<head>
	<title>{$stats->system['chan']} stats by {$stats->system['name']}</title>
	</head>
	<body>
	<h1>{$stats->system['chan']} Stats by {$stats->system['name']}</h1>
	{$stats->toptable()}
	</body>
	</html>");
?>
