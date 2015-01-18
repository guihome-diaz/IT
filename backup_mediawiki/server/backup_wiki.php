<?php
	// Zip library that uses Zlib compression.
	// Zip lib: http://ramui.com/articles/php-zip-files-and-directory.html
	// Zlib compress: http://www.zlib.net/
	include('recurseZip.php');

	// Database backup library
	// author Daniel López Azaña: http://www.daniloaz.com
	include('backup_mysql_db.php');
	
	
	// ##############################
	// Settings
	// ##############################

	// ***** Output folder *****
	$dstFolder = "/home/...";

	// ***** Database settings *****
	$dbName = 'myDb';
	$dbHost = 'dbServer';
	$dbUser = 'dbUser';
	$dbPassword = 'secret';
	// $dbTables = '*';
	$dbTables = "wiki_archive,wiki_category,wiki_categorylinks,wiki_change_tag,wiki_externallinks,wiki_external_user,wiki_filearchive,wiki_hitcounter,wiki_image,wiki_imagelinks,wiki_interwiki,wiki_ipblocks,wiki_iwlinks,wiki_job,wiki_l10n_cache,wiki_langlinks,wiki_logging,wiki_log_search,wiki_module_deps,wiki_msg_resource,wiki_msg_resource_links,wiki_objectcache,wiki_oldimage,wiki_page,wiki_pagelinks,wiki_page_props,wiki_page_restrictions,wiki_protected_titles,wiki_querycache,wiki_querycachetwo,wiki_querycache_info,wiki_recentchanges,wiki_redirect,wiki_revision,wiki_searchindex,wiki_sites,wiki_site_identifiers,wiki_site_stats,wiki_tag_summary,wiki_templatelinks,wiki_text,wiki_transcache,wiki_updatelog,wiki_uploadstash,wiki_user,wiki_user_former_groups,wiki_user_groups,wiki_user_newtalk,wiki_user_properties,wiki_valid_tag,wiki_watchlist";

	// ***** Folders to backup *****
	$srcWiki = "/home/...";
	$srcWikiUploadFiles = "/home/...";

	
	// ##############################
	// DB backup
	// ##############################
	$today = date("Y-m-d"); 
	$log = '';
	$backupDatabase = new Backup_Database($dbHost, $dbUser, $dbPassword, $dbName);
	$status = $backupDatabase->backupTables($dbTables, $dstFolder);
	if ($status) {
		$log .= "<p>";
		$log .= "<strong>Database backup complete!</strong><br>";
		$log .= "<ul>";
		$log .= "<li> DB --> saved to: ". $dstFolder . "/db-backup_" . $dbName . "_" . $today . ".zip </li>";
		$log .= "</ul>";
		$log .= "</p>";
	} else {
		$log .= "<p>";
		$log .= "<strong><span style='font-weight:bold; color:red'> Database backup failure </span></strong>";
		$log .= "<br> Please check the previous logs";
		$log .= "</p>";
	}
	
	
	// ##############################
	// Files backup
	// ##############################
	
	// Backup mediawiki
	$z1=new recurseZip();
	echo $z1->compress($srcWiki,$dstFolder);
	
	// Backup wiki related files
	$z2=new recurseZip();
	echo $z2->compress($srcWikiUploadFiles,$dstFolder);	
	
	$log .= "<p>";
	$log .= "<strong>Files backup complete!</strong><br>";
	$log .= "<ul>";
	$log .= "<li> " . $srcWiki . " --> saved to: " . $dstFolder . "/wiki_" . $today . ".zip </li>";
	$log .= "<li> " . $srcWikiUploadFiles . " --> saved to: " . $dstFolder . "/wiki_upload_files_" . $today . ".zip </li>";
	$log .= "</ul>";
	$log .= "</p>";
	
	echo $log;

?>
