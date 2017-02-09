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
		foreach(const(string) key, NodeInterface n; this.g.nodes) {
			this.write(n);
		}	

		this.indent++;
		foreach(const(string) key, Edge n; this.g.edges) {
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
		foreach(const(string) it, NodeInterface n; sg.nodes) {
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
			gformat("%s [\n", prepareName(n.name));
		} else {
			gformat("_%s [\n", prepareName(n.name));
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
			gformat("%s [\n", prepareName(n.name));
		} else {
			gformat("_%s [\n", prepareName(n.name));
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

		gformat(this.indent, "%s -> %s\n",
			prepareName(e.from), prepareName(e.to)
		);
		gformat(this.indent, "[\n");
		if(!e.label.empty) {
			writeLabel(e.label);
		}
		if(fromIsSubgraph && toIsSubgraph) {
			gformat(this.indent+1, ",ltail=%s,lhead=%s\n", 
				prepareName(e.from[0 .. $ - DummyString.length - 1]),
				prepareName(e.to[0 .. $ - DummyString.length - 1])
			);
		} else if(!fromIsSubgraph && toIsSubgraph) {
			gformat(this.indent+1, ",lhead=%s\n", 
				prepareName(e.to[0 .. $ - DummyString.length - 1]),
			);
		} else if(fromIsSubgraph && !toIsSubgraph) {
			gformat(this.indent+1,",ltail=%s\n", 
				prepareName(e.from[0 .. $ - DummyString.length - 1])
			);
		} 
		if(!e.edgeStyle.empty) {
			gformat(this.indent+1,",style=%s\n", e.edgeStyle);
		}
		if(!e.arrowStyleFrom.empty) {
			gformat(this.indent+1,",arrowhead=%s\n", e.arrowStyleFrom);
		}
		if(!e.arrowStyleTo.empty) {
			gformat(this.indent+1,",arrowtail=%s\n", e.arrowStyleTo);
		}
		if(!e.labelFrom.empty) {
			gformat(this.indent+1,",headlabel=%s\n", e.labelFrom);
		}
		if(!e.labelTo.empty) {
			gformat(this.indent+1,",taillabel=%s\n", e.labelTo);
		}
		gformat(this.indent+1, ",dir=\"both\"\n");
		gformat(this.indent, "]\n");
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
		auto tmp = this.nameStack[]
			.map!(a => format("cluster_%s", prepareName(a)));
		this.gformat("%s", tmp.joiner("_"));
	}

	final void formatPrefixClusterName() {
		gformat(this.indent, "");
		auto tmp = this.nameStack[]
			.map!(a => format("cluster_%s", prepareName(a)));
		this.gformat("%s", tmp.joiner("_"));
	}

	static string prepareName(string name) {
		import std.string : translate;
		dchar[dchar] tt = [' ':'_', '\n':'_', '\t':'_'];
		return translate(name, tt);
	}
}

unittest {
	import graph;
	import std.stdio : File;

	Graph g = new Graph();
	auto a = g.get!SubGraph("a");
	a.label =`<
		<table>
		<tr>
		<td> Module A</td>
		</tr>
		</table>
		>`;
	a.shape = "none";
	auto b = a.get!SubGraph("b");
	b.label =`<
		<table>
		<tr>
		<td> Module B</td>
		</tr>
		</table>
		>`;
	auto c = a.get!SubGraph("c");
	c.label =`<
		<table>
		<tr>
		<td> Module C</td>
		</tr>
		</table>
		>`;
	auto n = b.get!Node("node");
	n.label = `"Node1"`;
	n.shape = "box";

	auto n2 = g.get!Node("otherNode");
	n2.label = "otherNode";
	auto n3 = g.get!Node("stupidNode");
	n3.label = "stupidNode";

	auto e = g.get!Edge("edge1", "a.b.node", "otherNode");
	auto e2 = g.get!Edge("edge2", "a.b", "stupidNode");
	auto e3 = g.get!Edge("edge3", "a.c", "a.b");
	auto e4 = g.get!Edge("edge4", "otherNode", "stupidNode");
	auto e5 = g.get!Edge("edge5", "stupidNode", "a.c");

	//auto o = stderr.lockingTextWriter();
	auto f = File("test.dot", "w");
	auto o = f.lockingTextWriter();
	auto w = new Writer!(typeof(o))(g, o, "rankdir=LR");
	//f.close();

	version(linux) {
		import std.process;
		auto pid = spawnProcess(["dot", "-T", "png", "test.dot", "-o", "test.png"]);
		wait(pid);
