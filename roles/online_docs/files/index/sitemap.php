<?php

//
// The top level directory that will be indexed.
//
$root = $_SERVER['DOCUMENT_ROOT'];

//
// Functions.
//
function getSitemap($root) {
	$sites=array();
	foreach(glob($root . '/*/index.html') as $indexFile) {
		$content=file_get_contents($indexFile);
		if(preg_match("'<h1[^>]*>(.+)</h1>'i", $content, $matches)) {
			$title=$matches[1];
		} elseif(preg_match("'<title[^>]*>(.+)</title>'i", $content, $matches)) {
			$title=$matches[1];
		} else {
			$title='Site without a Title.';
		}
		#$relativeUrl = rawurlencode(str_replace($root . '/', '', $indexFile));
		$relativeUrl = implode("/", array_map("rawurlencode", explode("/", str_replace($root . '/', '', $indexFile))));
		array_push($sites, array(
			'relUrl' => $relativeUrl,
			'title'  => $title
		));
	}
	return($sites);
}

//
// Main.
//
ob_start();
echo '<ul>' . "\n";


$subWebsites = getSitemap($root);
foreach($subWebsites as $subWebsite) {
	echo '<li><a href="' . $subWebsite['relUrl'] . '">' . $subWebsite['title'] . '</a></li>' . "\n";
}

echo '</ul>' . "\n";
ob_end_flush();

?>
