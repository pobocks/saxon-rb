require 'saxon/processor'
require 'saxon/source'
require 'saxon/xdm'

module Saxon
  RSpec.describe XDM do
    context "creating Ruby wrapper objects from XDM items and Ruby values" do
      let(:doc_builder) { Saxon::Processor.create.document_builder }
      let(:source) { Saxon::Source.from_string("<doc/>", base_uri: "http://example.org/") }
      let(:doc_node) { doc_builder.build(source) }

      specify "s9api.XdmValue creates an XDM::Value" do
        s9_value = S9API::XdmValue.new([])
        expect(XDM.Item(s9_value)).to be_a(XDM::Value)
      end

      specify "s9api.XdmAtomicValue creates an XDM::AtomicValue" do
        s9_value = S9API::XdmAtomicValue.new(1)
        expect(XDM.Item(s9_value)).to be_a(XDM::AtomicValue)
      end

      specify "s9api.XdmNode creates an XDM::Node" do
        expect(XDM.Item(doc_node.to_java)).to be_a(XDM::Node)
      end

      specify "s9api.XdmExternalObject creates an XDM::ExternalObject" do
        s9_value = S9API::XdmExternalObject.new(1)
        expect(XDM.Item(s9_value)).to be_a(XDM::ExternalObject)
      end

      specify "s9api.XdmArray creates an XDM::Array" do
        s9_value = S9API::XdmArray.new()
        expect(XDM.Item(s9_value)).to be_a(XDM::Array)
      end

      specify "s9api.XdmMap creates an XDM::Map" do
        s9_value = S9API::XdmMap.new()
        expect(XDM.Item(s9_value)).to be_a(XDM::Map)
      end

      requires_pe do
        specify "s9api.XdmFunctionItem creates an XDM::FunctionItem" do
        end
      end

      context "existing XDM::* objects get passed through" do
        [XDM.AtomicValue(1), XDM.Array([1,2])].each do |xdm_item|
          specify "#{xdm_item.class.name} should be passed through unchanged" do
            expect(XDM.Item(xdm_item)).to be(xdm_item)
          end
        end

        specify "XDM Nodes should be passed through unchanged" do
          expect(XDM.Item(doc_node)).to be(doc_node)
        end
      end
    end
  end
end
