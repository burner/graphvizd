module graph;

import std.typecons : Rebindable, RefCounted;
import containers.hashmap;
import containers.dynamicarray;
import containers.cyclicbuffer;

public immutable DummyString = "__dummy";

interface NodeInterface {
	bool isAddingNodesAllowed() const;
}

class Graph : NodeInterface {
	HashMap!(string,NodeInterface) nodes;
	HashMap!(string,Edge) edges;
	bool firstEdgeCreated = false;

	string deapest(string path) const {
		import std.array : appender, Appender, empty;
		import std.stdio : writeln;
		void realPut(const Node ni, ref Appender!string app) {
			import std.format : formattedWrite;
			if(!app.data.empty) {
				app.put("_");
			}
			if((cast(SubGraph)ni) !is null) {
				app.formattedWrite("cluster_%s", ni.name);
			} else {
				app.formattedWrite("%s", ni.name);
			}
		}

		CyclicBuffer!string split;
		splitString(split, path);

		if(split.empty || !(split.front in this.nodes)) {
			return "";
		}

		Rebindable!(const Node) next = cast(const Node)this.nodes[split.front];
		auto app = appender!string();
		//app.put(split.front);
		realPut(next.get(), app);
		split.removeFront();

		while(!split.empty && next !is null) {
			SubGraph sg = cast(SubGraph)next;
			if(sg is null) {
				break;
			} else {
				if(split.front in sg.nodes) {
					next = cast(const Node)sg.nodes[split.front];
					//app.put(split.front);
					realPut(next.get(), app);
					split.removeFront();
				} else {
					break;
				}
			}
		}

		SubGraph lastSG = cast(SubGraph)next;
		//if(!split.empty && lastSG !is null) {
		if(lastSG !is null) {
			DummyNode dn = lastSG.get!DummyNode(DummyString);
			assert(dn !is null);
			//app.put(dn.name);
			realPut(dn, app);
		}

		return app.data;
	}

	T get(T)(in string name, in string from = "", in string to = "") 
			if(is(T == Edge)) 
	{
		import std.array : empty;
		firstEdgeCreated = true;
		if(name in this.edges) {
			return cast(T)this.edges[name];
		} else {
			assert(!from.empty);
			assert(!to.empty);
			T ret = new T(name, this.deapest(from), this.deapest(to));
			this.edges[name] = ret;
			return ret;
		}
	}
			
	T get(T)(in string name) if(!is(T == Edge)) {
		if(name in this.nodes) {
			return cast(T)this.nodes[name];
		} else {
			if(!this.isAddingNodesAllowed()) {
				throw new Exception("Node's can't be created after the "
					~ "first Edge has been created"
				);
			}
			T ret = new T(name, this);
			this.nodes[name] = ret;
			return ret;
		}
	}

	bool isAddingNodesAllowed() const {
		return !this.firstEdgeCreated;
	}
}

class Node : NodeInterface {
	const(string) name;
	NodeInterface parent;
	string label;
	string shape;
	string attributes;

	this(in string name, NodeInterface parent) {
		this.name = name;
		this.parent = parent;
	}

	bool isAddingNodesAllowed() const {
		assert(false, "This should never be called");
	}
}

class DummyNode : Node {
	this(Node parent) {
		super(DummyString, parent);
		super.attributes = `width="0", style = invis`;
		super.label = "";
		super.shape = "none";
	}
}

class SubGraph : Node {
	HashMap!(string,NodeInterface) nodes;

	this(in string name, NodeInterface parent) {
		assert(parent !is null);
		super(name, parent);
	}

	/*package*/ T get(T)(in string name) {
		if(name in this.nodes) {
			return cast(T)this.nodes[name];
		} else {
			static if(is(T == DummyNode)) {
				T ret = new T(this);
			} else {
				if(!this.isAddingNodesAllowed()) {
					throw new Exception("Node's can't be created after the "
						~ "first Edge has been created"
					);
				}
				T ret = new T(name, this);
			}
			this.nodes[name] = ret;
			return ret;
		}
	}

	T get(T)() if(is(T == DummyNode)) {
		if(name in this.nodes) {
			return cast(T)this.nodes[name];
		} else {
			T ret = new T(this);
			this.nodes[name] = ret;
			return ret;
		}
	}

	override bool isAddingNodesAllowed() const {
		assert(this.parent !is null);
		return this.parent.isAddingNodesAllowed();
	}
}

class Edge {
	const(string) name;
	const(string) from;
	const(string) to;
	string label;
	string arrowStyleFrom;
	string arrowStyleTo;
	string labelFrom;
	string labelTo;
	string edgeStyle;

	this(in string name, in string from, in string to) {
		this.name = name;
		this.from = from;
		this.to = to;
	}
}

private void splitString(O)(ref O or, in string str) {
	import std.algorithm.iteration : splitter;
	foreach(it; str.splitter(".")) {
		or.insert(it);
	}
}

unittest {
	import std.exception : assertThrown;
	auto g = new Graph();
	auto n = g.get!Node("a");
	auto m = g.get!Node("b");
	auto sg = g.get!SubGraph("sg");
	auto e = g.get!Edge("e", "a", "b");
	assertThrown(g.get!Node("c"));
	assert(n is g.get!Node("a"));
	assert(e is g.get!Edge("e"));
	assertThrown(sg.get!Node("sgNode"));
}

unittest {
	auto g = new Graph();
	auto a = g.get!SubGraph("a");
	assert(g.deapest("a") == "cluster_a___dummy");
	auto b = a.get!Node("b");
	assert(g.deapest("a.b") == "cluster_a_b");
	assert(g.deapest("c") == "");
	auto c = a.get!SubGraph("c");
	assert(g.deapest("a.c") == "cluster_a_cluster_c___dummy");
	assert(g.deapest("a.c.e") == "cluster_a_cluster_c___dummy");
	assert(g.deapest("a.d.e") == "cluster_a___dummy");
	auto d = c.get!Node("d");
	assert(g.deapest("a.c.d") == "cluster_a_cluster_c_d");
}

unittest {
	auto g = new Graph();
	auto a = g.get!SubGraph("a");
	auto ab = a.get!SubGraph("b");
	auto abc = ab.get!Node("c");

	auto b = g.get!SubGraph("b");
	auto bb = b.get!SubGraph("b");
	auto bc = bb.get!SubGraph("c");

	Edge e = g.get!Edge("ab_bbc", "a.b.c", "b.b.c");
	assert(e.from == "cluster_a_cluster_b_c", e.from);
	assert(e.to == "cluster_b_cluster_b_cluster_c___dummy", e.to);
}
