module writer;

class Writer(O) {
	import graph;
	import std.format : formattedWrite;
	import std.algorithm.iteration : splitter;
	//import std.algorithm.mutation : stripLeft;
	import std.string : stripLeft;
	import std.uni : isWhite;
	import std.traits;
	import std.range;

	Graph g;
	string config;
	O output;
	uint indent;

	this(O)(Graph g, O output, string config = "") {
		this.g = g;
		this.output = output;
		this.config = config;
		this.indent = 0;
		this.write();
	}

	final void write() {
		format("digraph G {\n");
		this.writeGraphConfig();
		format("}\n");
	}

	final void writeGraphConfig() {
		foreach(it; this.config.splitter()) {
			auto jt = it.stripLeft();
			format(1, "%s\n", jt);
		}
	}

	void format(A...)(uint ind, string str, A a) {
		for(; ind > 0; --ind) {
			this.output.put("\t");
		}
		format(str, a);
	}

	void format(A...)(string str, A a) {
		formattedWrite(this.output, str, a);
	}
}
