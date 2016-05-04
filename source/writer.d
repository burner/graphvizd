module writer;

import containers.dynamicarray;

class Writer(O) {
	import graph;
	import std.format : format, formattedWrite;
	import std.algorithm.iteration : splitter;
	import std.string : stripLeft;
	import std.uni : isWhite;
	import std.traits;
	import std.range;

	Graph g;
	string config;
	O output;
	uint indent;
	DynamicArray!string nameStack;

	this(O)(Graph g, O output, string config = "") {
		this.g = g;
		this.output = output;
		this.config = config;
		this.indent = 0;
		this.write();
	}

	final void write() {
		gformat("digraph G {\n");
		gformat(1, "compound=true;\n");
		this.writeGraphConfig();
		foreach(key; this.g.nodes.keys()) {
			NodeInterface n = this.g.nodes[key];
			this.write(n);
		}	

		this.indent++;
		foreach(key; this.g.edges.keys()) {
			Edge n = this.g.edges[key];
			this.write(n);
		}
		this.indent--;
		gformat("}\n");
	}

	final void write(NodeInterface ni) {
		SubGraph sg = cast(SubGraph)ni;
		if(sg !is null) {
			this.write(sg);
			return;
		} 
		DummyNode d = cast(DummyNode)ni;
		if(d !is null) {
			this.write(d);
			return;
		}
		Node n = cast(Node)ni;
		if(n !is null) {
			this.write(n);
			return;
		}
	}

	final void write(SubGraph sg) {
		nameStack.insert(sg.name);
		this.indent++;

		this.formatPrefixSubGraphName();
		gformat(" {\n");
		this.writeLabel(sg.label);
		this.writeShape(sg.shape);
		this.writeAttributes(sg.attributes);
		foreach(it; sg.nodes.keys()) {
			NodeInterface n = sg.nodes[it];
			this.write(n);
		}

		gformat(this.indent, "}\n");
		nameStack.remove(nameStack.length - 1);
		this.indent--;
	}

	final void write(Node n) {
		this.indent++;

		this.formatPrefixClusterName();
		if(this.nameStack.empty) {
			gformat("%s [\n", n.name);
		} else {
			gformat("_%s [\n", n.name);
		}
		this.writeLabel(n.label);
		this.writeShape(n.shape);
		this.writeAttributes(n.attributes);
		gformat(this.indent, "]\n");

		this.indent--;
	}

	final void write(DummyNode n) {
		this.indent++;

		this.formatPrefixClusterName();
		if(this.nameStack.empty) {
			gformat("%s [\n", n.name);
		} else {
			gformat("_%s [\n", n.name);
		}
		gformat(this.indent, "label=\"\"\n");
		this.writeShape(n.shape);
		this.writeAttributes(n.attributes);
		gformat(this.indent, "]\n");

		this.indent--;
	}

	final void write(Edge e) {
		import std.algorithm.searching : endsWith;

		bool fromIsSubgraph = e.from.endsWith("__dummy");
		bool toIsSubgraph = e.to.endsWith("__dummy");

		if(fromIsSubgraph && toIsSubgraph) {
			gformat(this.indent, "%s -> %s [ltail=%s,lhead=%s]\n", 
				e.from, e.to, 
				e.to[0 .. $ - DummyString.length - 1],
				e.from[0 .. $ - DummyString.length - 1]
			);
		} else if(!fromIsSubgraph && toIsSubgraph) {
			gformat(this.indent, "%s -> %s [lhead=%s]\n", 
				e.from, e.to, 
				e.to[0 .. $ - DummyString.length - 1],
			);
		} else if(fromIsSubgraph && !toIsSubgraph) {
			gformat(this.indent, "%s -> %s [ltail=%s]\n", 
				e.from, e.to, 
				e.from[0 .. $ - DummyString.length - 1]
			);
		} else {
			gformat(this.indent, "%s -> %s\n", 
				e.from, e.to, 
			);
		}
	}

	final void writeGraphConfig() {
		this.indent++;
		this.writeMultiLineString(this.config);
		this.indent--;
	}

	void gformat(A...)(uint ind, string str, A a) {
		for(; ind > 0; --ind) {
			this.output.put("\t");
		}
		gformat(str, a);
	}

	void gformat(A...)(string str, A a) {
		formattedWrite(this.output, str, a);
	}

	final void writeAttributes(string attr) {
		if(!attr.empty) {
			this.indent++;
			this.writeMultiLineString!','(attr);
			this.indent--;
		}
	}

	final void writeLabel(string label) {
		if(!label.empty) {
			this.indent++;
			gformat(this.indent, "label = ");
			this.writeMultiLineString(label, true);
			this.indent--;
		}
	}

	final void writeShape(string shape) {
		if(!shape.empty) {
			this.indent++;
			gformat(this.indent, "shape = %s\n", shape);
			this.indent--;
		}
	}

	final void writeMultiLineString(char sc = '\n')(string label, 
			bool doNotIndent = false) 
	{
		foreach(it; label.splitter(sc)) {
			auto jt = it.stripLeft();
			if(doNotIndent) {
				gformat("%s\n", jt);
				doNotIndent = false;
			} else {
				gformat(this.indent, "%s\n", jt);
			}
		}
	}

	import std.algorithm.iteration : joiner, map;

	final void formatPrefixSubGraphName() {
		gformat(this.indent, "subgraph ");
		auto tmp = this.nameStack[].map!(a => format("cluster_%s", a));
		this.gformat("%s", tmp.joiner("_"));
	}

	final void formatPrefixClusterName() {
		gformat(this.indent, "");
		auto tmp = this.nameStack[].map!(a => format("cluster_%s", a));
		this.gformat("%s", tmp.joiner("_"));
	}
}
