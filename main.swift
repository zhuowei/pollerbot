import Foundation
import PerfectLib
import cURL

let curl = CURL()

func doHead(url: String) -> (Int, Int) {
	curl.reset()
	curl.setOption(CURLOPT_HEADER, int:1)
	curl.setOption(CURLOPT_NOBODY, int:1)
	curl.url = url
	let (curlCode, _, _) = curl.performFully()
	return (curlCode, curl.responseCode)
}

func initDatabase() throws -> (SQLite) {
	let sqlite = try SQLite("poller.db")
	try sqlite.execute("CREATE TABLE IF NOT EXISTS poller (" +
			"id TEXT PRIMARY KEY)")
	return sqlite
}

func pad(instr: String, padDigit: String, length: Int) -> String {
	var out = instr
	while out.characters.count < length {
		out = padDigit + out 
	}
	return out
}

func urlForDate(date: NSDateComponents) -> String {
	//return "http://www.girlgeniusonline.com/ggmain/strips/" + 
	return "http://localhost:8000/" + 
		"ggmain" + pad(String(date.year), padDigit: "0", length: 4) +
			pad(String(date.month), padDigit: "0", length: 2) +
			pad(String(date.day), padDigit: "0", length: 2) +
			".jpg"
}

func shortDate(date: NSDateComponents) -> String {
	//return "http://www.girlgeniusonline.com/ggmain/strips/" + 
	return pad(String(date.year), padDigit: "0", length: 4) +
			pad(String(date.month), padDigit: "0", length: 2) +
			pad(String(date.day), padDigit: "0", length: 2)
}

func alreadyPolled(sqlite: SQLite, url: String) throws -> (Bool) {
	var yep = false
	try sqlite.forEachRow("SELECT count(id) FROM poller WHERE id = \"" + url + "\"", handleRow: {
		(stmt, count) -> () in
		if stmt.columnInt(0) != 0 {
			yep = true
		}
	})
	return yep
}

func addToDatabase(sqlite: SQLite, url: String) throws {
	try sqlite.execute("INSERT INTO poller (id) VALUES (\"" + url + "\")")
}

func urlEscape(url: String) -> String {
	return url.stringByAddingPercentEncodingWithAllowedCharacters(
		NSCharacterSet.URLHostAllowedCharacterSet())!
}

func postToTropes(message: String) {
	curl.reset()
	curl.setOption(CURLOPT_POST, int:1)
	let postfields = "addressee=polar&subject=testsubject&pm_text="
		+ urlEscape(message)
	let cookies = "COOKIES"
	//curl.url = "http://tvtropes.org/pmwiki/w_pmsend.php"
	curl.url = "http://localhost:9000/"
	postfields.withCString {
		postfields_cs in
		curl.setOption(CURLOPT_POSTFIELDS, v:UnsafeMutablePointer<Void>(postfields_cs))
		cookies.withCString {
			cookies_cs in
			curl.setOption(CURLOPT_COOKIE, v:UnsafeMutablePointer<Void>(cookies_cs))
			curl.performFully()
		}
	}
}

func doPoll() throws {
	let sqlite = try initDatabase()
	let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
	let curdate_utc = NSDate()
	// what the heck, Foundation on Linux
	let unitFlags : NSCalendarUnit = NSCalendarUnit(rawValue:
			NSCalendarUnit.Year.rawValue |
			NSCalendarUnit.Month.rawValue |
			NSCalendarUnit.Day.rawValue)
	var tropesPost = ""
	var foundOne = false
	for i in 0...7 {
		let newdate = curdate_utc.dateByAddingTimeInterval(
			Double(i*24*60*60))
		let components = calendar.components(unitFlags,
			fromDate: newdate)!
		let url = urlForDate(components)
		if try alreadyPolled(sqlite, url:url) {
			continue
		}
		let (curlResult, httpResult) = doHead(url)
		if (curlResult != 0 || httpResult != 200) {
			continue
		}
		print("Found a comic", url)
		foundOne = true
		// try addToDatabase(sqlite, url:url)
		tropesPost += "[[" + url + "| Comic for " +
			shortDate(components) + "]]\n"
	}
	if foundOne {
		postToTropes(tropesPost)
	}
}

try doPoll()
