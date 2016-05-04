import std.stdio;

import graph;
import writer;

void main() {
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
	auto n = b.get!Node("node");
	n.label = `"Node1"`;
	n.shape = "box";

	auto n2 = g.get!Node("otherNode");
	n2.label = "otherNode";
	auto n3 = g.get!Node("stupidNode");
	n3.label = "stupidNode";

	auto e = g.get!Edge("edge1", "a.b.node", "otherNode");
	auto e2 = g.get!Edge("edge2", "a.b", "stupidNode");

	//auto o = stderr.lockingTextWriter();
	auto f = File("test.dot", "w");
	auto o = f.lockingTextWriter();
	auto w = new Writer!(typeof(o))(g, o, "rankdir=LR");
}
